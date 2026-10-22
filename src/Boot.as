package
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.InteractiveObject;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.SimpleButton;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.net.SharedObject;
    import flash.net.URLRequest;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    import flash.utils.Timer;

    /**
     * Capoo (Touch Hands / 摸摸手) - revival boot shim.
     *
     * ----------------------------------------------------------------------
     * WHY THIS EXISTS
     * ----------------------------------------------------------------------
     * The shipped capoo.swf has its entire flash.data / SQLConnection layer
     * STUBBED OUT (the methods Query / SelectGameDResult / AddGameRowResult /
     * RunUpdateResult ... are empty 3-byte bodies). As a result the leaderboard
     * array `role` is never loaded from disk, so every row renders as
     * "undefined" and the game's own record logic ("score > role[ss][1]"
     * => "number > undefined" => false) never fires. The game's name-entry clip
     * (`new_name`) is also parked off-screen at x=-609 and nothing ever moves it
     * in, because the code that did so lived behind the dead DB callbacks.
     *
     * This shim RESTORES the missing pieces without replacing the game's own
     * UI. It uses the game's own `new_name` clip and its own data model:
     *   - seeds `role` once from a SharedObject so the game's insertion sort
     *     has real numbers to compare against
     *   - reproduces the game's own insertion on round end (frame7 semantics)
     *     and flags a new record (getnew)
     *   - moves the game's OWN name-entry clip on screen and makes its TextField
     *     a real editable input (the authored one is non-editable + embedded font
     *     with no Latin glyphs), then forces the soft keyboard
     *   - confirms the name through the game's OWN OK button (an invisible
     *     hotspot is laid exactly over it, because the game's own handler
     *     go_again() is broken - it writes the name into the SCORE slot) and
     *     stores the TYPED name into role[gsit][0]
     *   - mirrors the (sorted) board into name1..5 / scr1..5 / hit_point and
     *     persists it to the SharedObject
     *
     * ----------------------------------------------------------------------
     * STABILITY RULES (learned the hard way - do not break these)
     * ----------------------------------------------------------------------
     * 1. NEVER touch the display list from inside a mouse/key event handler.
     *    Doing gotoAndStop()/hide()/focus changes while an Android soft
     *    keyboard is attached crashes the AIR runtime. All teardown is
     *    deferred to the next ENTER_FRAME (see pendingClose / doClose()).
     * 2. NEVER let the game's go_again() run: it writes the name into
     *    role[gsit][1] (the score slot) instead of role[gsit][0]. The game's OK
     *    button is made mouseEnabled=false and covered by our own hotspot.
     * 3. An uncaught error handler is installed on the stage, so a stray
     *    exception can never pop the AIR error dialog and kill the app.
     */
    [SWF(width="480", height="800", frameRate="24", backgroundColor="#000000")]
    public class Boot extends Sprite
    {
        // ----------------------------------------------------------- constants
        private static const ROWS:int = 5;
        private static const DEFAULT_NAME:String = "無";
        private static const DEFAULT_PLAYER:String = "CaPoo";
        private static const LOG:Boolean = true;
        private static const NAME_TIMEOUT_MS:int = 30000;
        // how far the name panel is lifted when the Android soft keyboard
        // covers the lower part of the screen (the OK button lives there)
        private static const KBD_LIFT:Number = 215;

        // -------------------------------------------------------------- state
        private var content:MovieClip;
        private var so:SharedObject;
        private var board:Array = [];
        private var seeded:Boolean = false;
        private var lastSig:String = "";

        // record / prompt bookkeeping (the game owns `role` order; we only read
        // it and mirror a sorted copy for display, never reorder the real array)
        private var prevGetnew:Boolean = false;
        private var prevFrame:int = -1;
        private var lastRecorded:int = -1;
        private var nameClip:MovieClip;
        private var promptShown:Boolean = false;
        private var promptGsit:int = -1;
        private var dismissTimer:Timer = null;
        private var nameField:TextField = null;
        private var hotspot:Sprite = null;
        private var pendingClose:Boolean = false;
        private var closedName:String = "";
        private var baseY:Number = 0;
        private var baseX:Number = 0;
        private var t0:Number = 0;

        // score we inserted for `lastGsit`, used to repair the row if the
        // game's broken go_again() ever managed to write into the score slot
        private var lastGsit:int = -1;
        private var lastScore:int = 0;

        public function Boot()
        {
            super();

            t0 = (new Date()).getTime();
            loadBoard();

            // catch any uncaught runtime error before AIR shows the fatal
            // error dialog and kills the app
            try
            {
                stage.addEventListener(ErrorEvent.ERROR, onUncaughtError, true);
            }
            catch (err:Error)
            {
            }

            // the Android soft keyboard covers the lower part of the screen,
            // so the name panel has to move up while it is open.
            // (the AIR mobile profile has no SoftKeyboardEvent constants, so
            //  the event types are used as plain strings)
            try
            {
                stage.addEventListener("softKeyboardHide", onKbHide, true);
            }
            catch (err:Error)
            {
            }

            var ldr:Loader = new Loader();
            ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
            ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            ldr.contentLoaderInfo.addEventListener(ErrorEvent.ERROR, onSwfError);

            var ctx:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);

            var bytes:ByteArray = readAppFile("capoo.swf");
            if (bytes != null)
            {
                try
                {
                    ldr.loadBytes(bytes, ctx);
                }
                catch (err:Error)
                {
                    ldr.load(new URLRequest("capoo.swf"), ctx);
                }
            }
            else
            {
                ldr.load(new URLRequest("capoo.swf"), ctx);
            }

            addChild(ldr);

            if (LOG)
            {
                try
                {
                    var f:File = File.applicationStorageDirectory.resolvePath("ranklog.txt");
                    if (f.exists)
                        f.deleteFile();
                }
                catch (err:Error)
                {
                }
            }
        }

        // -------------------------------------------------------------- logging

        private function log(msg:String):void
        {
            if (!LOG)
                return;
            try
            {
                var f:File = File.applicationStorageDirectory.resolvePath("ranklog.txt");
                var fs:FileStream = new FileStream();
                fs.open(f, FileMode.APPEND);
                fs.writeUTFBytes("[" + (new Date()).getTime() + "] " + msg + "\n");
                fs.close();
            }
            catch (err:Error)
            {
            }
        }

        private function onUncaughtError(e:ErrorEvent):void
        {
            log("UNCAUGHT :: " + e.text);
            try
            {
                e.preventDefault();
            }
            catch (err:Error)
            {
            }
        }

        // ------------------------------------------------------------------ io

        private function readAppFile(name:String):ByteArray
        {
            try
            {
                var f:File = File.applicationDirectory.resolvePath(name);
                if (!f.exists)
                    return null;

                var fs:FileStream = new FileStream();
                fs.open(f, FileMode.READ);
                var out:ByteArray = new ByteArray();
                fs.readBytes(out);
                fs.close();

                return out.length > 1024 ? out : null;
            }
            catch (err:Error)
            {
                return null;
            }
        }

        private function loadBoard():void
        {
            board = [];

            try
            {
                so = SharedObject.getLocal("capooRank");
            }
            catch (err:Error)
            {
                so = null;
            }

            var saved:* = so != null ? so.data.board : null;

            for (var i:int = 0; i < ROWS; i++)
            {
                var n:String = DEFAULT_NAME;
                var s:int = 0;

                if (saved is Array && i < saved.length && saved[i] != null)
                {
                    if (saved[i].n != null)
                        n = String(saved[i].n);
                    if (saved[i].s != null)
                        s = int(saved[i].s);
                }

                board.push({n: n, s: s});
            }
        }

        private function saveBoard():void
        {
            if (so == null)
                return;

            try
            {
                so.data.board = board;
                so.flush();
            }
            catch (err:Error)
            {
            }
        }

        // -------------------------------------------------------------- loading

        private function onLoaded(e:Event):void
        {
            content = (e.target as LoaderInfo).content as MovieClip;
            addEventListener(Event.ENTER_FRAME, onTick);
        }

        private function onIOError(e:IOErrorEvent):void
        {
            log("IO_ERROR " + e.text);
        }

        private function onSwfError(e:ErrorEvent):void
        {
            log("SWF_ERROR " + e.text);
        }

        // ------------------------------------------------------------ main loop

        private function onTick(e:Event):void
        {
            if (content == null)
                return;

            var role:Array = null;
            try
            {
                role = content["role"] as Array;
            }
            catch (err:Error)
            {
                return;
            }

            if (role == null)
                return;

            if (!seeded)
            {
                seedRole(role);
                seeded = true;
                log("SEEDED " + describe(role));
            }

            logFrameState();
            cacheNameClip();
            keepClipOnTop();

            repairScoreSlot(role);
            recordRoundIfNeeded(role);
            watchNewRecord(role);
            scrubPlaceholders(content);
            syncDisplay(role);

            // teardown always happens here, never inside an event handler
            if (pendingClose)
            {
                pendingClose = false;
                doClose();
            }
        }

        /**
         * The game's own insertion lives in frame7(), which only runs when the
         * game frame is entered, so a finished round is only recorded when the
         * player starts the *next* game. Reproduce the same insertion (same
         * semantics, same gsit/getnew bookkeeping) as soon as we are back on the
         * menu/rank/over frame, then hand over to the game's own name-entry clip.
         */
        private function recordRoundIfNeeded(role:Array):void
        {
            var label:String = "";
            try
            {
                label = String(content.currentFrameLabel);
            }
            catch (err:Error)
            {
            }

            if (label != "menu" && label != "rank" && label != "over")
                return;

            var hs:Number = 0;
            try
            {
                hs = Number(content["hit_sum"]);
            }
            catch (err:Error)
            {
                return;
            }

            if (isNaN(hs) || hs <= 0 || int(hs) == lastRecorded)
                return;

            var score:int = int(hs);
            var ss:int = 0;
            var found:Boolean = false;
            var gname:* = null;
            var gscr:* = null;
            var gsit:int = -1;

            while (ss < ROWS && ss < role.length)
            {
                var ent:* = role[ss];
                if (!(ent is Array))
                {
                    ent = [];
                    role[ss] = ent;
                }

                if (!found)
                {
                    if (score > Number(ent[1] == null ? 0 : ent[1]))
                    {
                        found = true;
                        gname = ent[0];
                        gscr = ent[1];
                        ent[1] = score;
                        gsit = ss;
                    }
                }
                else
                {
                    var sn:* = ent[0];
                    var sc:* = ent[1];
                    ent[0] = gname;
                    ent[1] = gscr;
                    gname = sn;
                    gscr = sc;
                }

                ss++;
            }

            lastRecorded = score;

            // stop the game's frame7() from inserting the same score again
            try
            {
                content["hit_sum"] = 0;
            }
            catch (err:Error)
            {
            }

            if (found)
            {
                lastGsit = gsit;
                lastScore = score;

                try
                {
                    content["gsit"] = gsit;
                    content["getnew"] = true;
                }
                catch (err:Error)
                {
                }

                log("RECORDED score=" + score + " gsit=" + gsit + " role=" + describe(role));
                showGameNameClip(role);
            }
            else
            {
                log("NOT TOP5 score=" + score + " role=" + describe(role));
            }
        }

        /**
         * The game's own go_again() writes the name into role[gsit][1] - the
         * SCORE slot. If that ever happens, move the name back to the name slot
         * and restore the score we inserted. Self-healing, so a stray click on
         * the game's own button can never corrupt the board.
         */
        private function repairScoreSlot(role:Array):void
        {
            if (lastGsit < 0 || lastGsit >= role.length)
                return;

            var ent:* = role[lastGsit];
            if (!(ent is Array))
                return;

            var raw:* = ent[1];
            if (raw == null)
                return;

            // a String (or a non-numeric value) in the score slot == the game's
            // go_again() wrote the name there by mistake
            if (raw is String || (raw is Number && isNaN(Number(raw))))
            {
                var nm:String = String(raw);
                if (nm != "" && nm != "null" && nm != "undefined")
                {
                    ent[0] = nm;
                    ent[1] = lastScore;
                    log("REPAIRED role[" + lastGsit + "] name=" + nm + " score=" + lastScore);
                }
            }
        }

        /** the clip is only on the display list while the "over" frame is up */
        private function cacheNameClip():void
        {
            try
            {
                var c:* = content["new_name"];
                if (c is MovieClip && (c as MovieClip).parent != null)
                {
                    // while a prompt is open we keep OUR instance, even if the
                    // game creates a new one on a later pass
                    if (!promptShown || nameClip == null)
                        nameClip = c as MovieClip;
                }
            }
            catch (err:Error)
            {
            }
        }

        /**
         * The game's name panel only exists on the "over" frame - the moment
         * the game advances to another frame the clip is removed from the
         * display list and the prompt would vanish in the middle of typing.
         * Re-attach it so the player can always finish entering their name.
         */
        private function keepClipOnTop():void
        {
            if (nameClip == null)
                return;
            try
            {
                if (nameClip.parent == null)
                {
                    if (!promptShown)
                        return;

                    content.addChild(nameClip);
                    nameClip.visible = true;
                    nameClip.x = baseX;
                    nameClip.y = baseY;
                    log("panel re-attached to the display list");
                }
                else if (nameClip.parent == content)
                {
                    content.setChildIndex(nameClip, content.numChildren - 1);
                }
            }
            catch (err:Error)
            {
            }
        }

        private function logFrameState():void
        {
            var frame:int = -1;
            var label:String = "";
            try
            {
                frame = content.currentFrame;
                label = String(content.currentFrameLabel);
            }
            catch (err:Error)
            {
            }

            if (frame == prevFrame)
                return;
            prevFrame = frame;

            var hs:String = "?";
            try
            {
                hs = String(content["hit_sum"]);
            }
            catch (err:Error)
            {
            }

            var gn:String = "?";
            try
            {
                gn = String(content["getnew"]);
            }
            catch (err:Error)
            {
            }

            log("frame=" + frame + " label=" + label + " hs=" + hs + " getnew=" + gn
                + " role=" + describe(content["role"] as Array));
        }

        /**
         * Fix the game's name-entry TextField so it is actually usable:
         *   - it is NOT an input field by default and uses an embedded font that
         *     has no Latin glyphs, so "CaPoo" renders as blank and taps do nothing
         *   - make it a real system-font editable input, lift it above the white
         *     rounded-rect graphic (depth 9) that was hiding the text, and
         *   - force stage focus so the soft keyboard opens for editing
         */
        private function prepareNameField(clip:MovieClip):void
        {
            var nf:* = null;
            try
            {
                nf = clip["newname"];
            }
            catch (err:Error)
            {
            }

            if (!(nf is TextField))
            {
                log("newname field missing");
                return;
            }

            var field:TextField = nf as TextField;

            // the authored field is only ~11px tall and sits behind a white
            // rounded-rect graphic, so a 19px font overflows / is clipped
            field.x = -100;
            field.y = -24;
            field.width = 200;
            field.height = 34;
            field.background = true;
            field.backgroundColor = 0xFFFFFF;
            field.border = true;
            field.borderColor = 0x5A3E2B;

            field.embedFonts = false;
            field.type = TextFieldType.INPUT;
            field.selectable = true;
            field.mouseEnabled = true;
            field.needsSoftKeyboard = true;
            field.maxChars = 10;

            var fmt:TextFormat = new TextFormat("_sans", 19, 0x333333);
            fmt.align = "center";
            field.defaultTextFormat = fmt;
            field.textColor = 0x333333;

            // default the field to the saved name (or "CaPoo"); the authored
            // text may be "null"/"undefined" (lastname was null) -> never show that
            var nm:String = String(field.text);
            if (nm == "" || nm == "null" || nm == "undefined")
                nm = playerName();
            field.text = "";
            field.text = nm;
            field.setTextFormat(fmt);

            // a white rounded-rect graphic sits at depth 9, above the field at
            // depth 8, and hides the text -> lift the field to the top
            try
            {
                clip.setChildIndex(field, clip.numChildren - 1);
            }
            catch (err:Error)
            {
                log("raise field failed: " + err.message);
            }

            try
            {
                field.setSelection(field.text.length, field.text.length);
            }
            catch (err:Error)
            {
            }

            clip.mouseChildren = true;
            clip.mouseEnabled = true;

            nameField = field;

            // force focus so the soft keyboard appears and the player can edit
            try
            {
                stage.focus = field;
                if (field.requestSoftKeyboard is Function)
                    field.requestSoftKeyboard();
                log("focus requested text=" + field.text);
            }
            catch (err:Error)
            {
                log("focus err " + err.message);
            }

            log("NAME FIELD ready text=" + field.text
                + " wh=" + field.width + "x" + field.height
                + " color=" + field.textColor + " emb=" + field.embedFonts
                + " vis=" + field.visible + " a=" + field.alpha);
        }

        /**
         * Lay an invisible hotspot exactly over the game's own OK button and
         * make the game's button non-interactive.
         *
         * The game's own handler (go_again) is broken - it writes the name into
         * role[gsit][1], the SCORE slot - and running it while the Android soft
         * keyboard is attached is what used to crash the game. So: the artwork
         * stays exactly the game's, but the click is handled by us.
         */
        private function installOkHotspot(clip:MovieClip):void
        {
            removeHotspot();

            var okB:* = null;
            try
            {
                okB = clip["ok"];
            }
            catch (err:Error)
            {
            }

            if (!(okB is DisplayObject))
            {
                log("ok button missing");
                return;
            }

            // keep the artwork, kill the game's own (broken) click handling
            try
            {
                (okB as InteractiveObject).mouseEnabled = false;
            }
            catch (err:Error)
            {
            }

            var r:Rectangle;
            try
            {
                r = (okB as DisplayObject).getBounds(clip);
            }
            catch (err:Error)
            {
                log("ok bounds err " + err.message);
                return;
            }

            if (r.width <= 0 || r.height <= 0)
            {
                log("ok bounds empty " + r.width + "x" + r.height);
                return;
            }

            var sp:Sprite = new Sprite();
            sp.graphics.beginFill(0x000000, 0.01);
            sp.graphics.drawRect(r.x, r.y, r.width, r.height);
            sp.graphics.endFill();
            sp.mouseEnabled = true;
            sp.mouseChildren = false;
            sp.addEventListener(MouseEvent.CLICK, onHotspotClick);
            sp.addEventListener(MouseEvent.MOUSE_DOWN, onHotspotDown);

            try
            {
                clip.addChild(sp);
                hotspot = sp;
                log("OK hotspot installed at " + r.x + "," + r.y + " " + r.width + "x" + r.height);
            }
            catch (err:Error)
            {
                log("hotspot add err " + err.message);
            }
        }

        private function removeHotspot():void
        {
            if (hotspot == null)
                return;
            try
            {
                hotspot.removeEventListener(MouseEvent.CLICK, onHotspotClick);
                hotspot.removeEventListener(MouseEvent.MOUSE_DOWN, onHotspotDown);
                if (hotspot.parent != null)
                    hotspot.parent.removeChild(hotspot);
            }
            catch (err:Error)
            {
            }
            hotspot = null;
        }

        private function onHotspotDown(ev:MouseEvent):void
        {
            log("HOTSPOT down -> confirm");
            requestConfirm();
        }

        private function onHotspotClick(ev:MouseEvent):void
        {
            log("HOTSPOT click -> confirm");
            requestConfirm();
        }

        /**
         * Stage-level MOUSE_DOWN hit-test for the game's own OK button - a
         * backup in case the moved clip does not get the touch at all.
         */
        private function onStageDown(ev:MouseEvent):void
        {
            log("STAGE down " + ev.stageX + "," + ev.stageY);

            if (nameClip == null || !nameClip.visible)
                return;

            resetDismissTimer();

            var okB:* = null;
            try
            {
                okB = nameClip["ok"];
            }
            catch (err:Error)
            {
            }

            if (okB != null && okB is DisplayObject)
            {
                var r:Rectangle;
                try
                {
                    r = (okB as DisplayObject).getBounds(stage);
                }
                catch (err:Error)
                {
                    return;
                }

                log("STAGE down okRect=" + r.x + "," + r.y + "," + r.width + "," + r.height);

                if (r.contains(ev.stageX, ev.stageY))
                {
                    log("OK hit -> confirm");
                    requestConfirm();
                    return;
                }
            }

            // a tap on the field keeps it focused / re-opens the keyboard
            if (nameField != null)
            {
                try
                {
                    var fr:Rectangle = nameField.getBounds(stage);
                    if (fr.contains(ev.stageX, ev.stageY))
                    {
                        try
                        {
                            stage.focus = nameField;
                            nameField.requestSoftKeyboard();
                        }
                        catch (e2:Error)
                        {
                        }
                    }
                }
                catch (err:Error)
                {
                }
            }
        }

        /**
         * The Android soft keyboard covers roughly the lower 45% of the
         * screen, which is exactly where the game's OK button sits. Lift the
         * whole name panel while the keyboard is open so the player can always
         * reach the OK button.
         */
        private function onKbHide(e:Event):void
        {
            log("SOFT KEYBOARD hide");
            applyKeyboardOffset(false);
        }

        private function applyKeyboardOffset(lift:Boolean):void
        {
            if (nameClip == null || !nameClip.visible)
                return;

            try
            {
                var want:Number = lift ? baseY - KBD_LIFT : baseY;
                if (nameClip.y != want)
                {
                    nameClip.y = want;
                    log("panel moved to y=" + want + " (lift=" + lift + ")");
                }
            }
            catch (err:Error)
            {
            }
        }

        /** soft-keyboard Done / Enter confirms the name */
        private function onNameKeyDown(ev:KeyboardEvent):void
        {
            resetDismissTimer();

            if (ev.keyCode == Keyboard.ENTER || ev.keyCode == 10)
            {
                log("KEY enter -> confirm");
                requestConfirm();
            }
        }

        /**
         * Confirm is requested from an event handler but performed in the next
         * ENTER_FRAME: never mutate the display list / focus inside a touch
         * handler while the Android soft keyboard is attached.
         */
        private function requestConfirm():void
        {
            if (pendingClose)
                return;

            pendingClose = true;
            closedName = readTypedName();
            log("CONFIRM requested name=" + closedName);
        }

        private function readTypedName():String
        {
            var typed:String = "";
            if (nameField != null)
            {
                try
                {
                    typed = String(nameField.text);
                }
                catch (err:Error)
                {
                }
            }
            typed = trim(typed);
            return (typed != "") ? typed : playerName();
        }

        /**
         * Store the name into role[gsit][0] and persist it as `lastname`.
         * The score slot is left alone - the game's own go_again() would have
         * overwritten it with the name, which is exactly the bug we avoid.
         */
        private function applyName():void
        {
            var finalName:String = (closedName != "") ? closedName : playerName();

            var role:Array = null;
            try
            {
                role = content["role"] as Array;
            }
            catch (err:Error)
            {
            }

            if (role != null && promptGsit >= 0 && promptGsit < role.length
                && role[promptGsit] is Array)
            {
                role[promptGsit][0] = finalName;
                log("NAMED role[" + promptGsit + "][0]=" + finalName);
            }

            try
            {
                content["lastname"] = finalName;
            }
            catch (err:Error)
            {
            }
            try
            {
                content["getnew"] = false;
            }
            catch (err:Error)
            {
            }
        }

        private function trim(s:String):String
        {
            while (s.length > 0 && (s.charAt(0) == " " || s.charAt(0) == "\t" || s.charAt(0) == "\n"))
                s = s.substr(1);
            while (s.length > 0 && (s.charAt(s.length - 1) == " " || s.charAt(s.length - 1) == "\t" || s.charAt(s.length - 1) == "\n"))
                s = s.substr(0, s.length - 1);
            return s;
        }

        /** the actual teardown - always runs from ENTER_FRAME */
        private function doClose():void
        {
            applyName();

            try
            {
                if (dismissTimer != null)
                {
                    dismissTimer.stop();
                    dismissTimer = null;
                }
            }
            catch (err:Error)
            {
            }

            try
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageDown, true);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, onNameKeyDown);
            }
            catch (err:Error)
            {
            }

            removeHotspot();

            // close the soft keyboard the safe way: release the soft-keyboard
            // request first, only then drop the focus
            try
            {
                if (nameField != null)
                {
                    nameField.needsSoftKeyboard = false;
                    nameField.type = TextFieldType.DYNAMIC;
                }
            }
            catch (err:Error)
            {
            }
            try
            {
                stage.focus = null;
            }
            catch (err:Error)
            {
            }

            if (nameClip != null)
            {
                nameClip.visible = false;
                nameClip.x = -609;
                nameClip.y = baseY;
            }
            promptShown = false;
            promptGsit = -1;
            nameField = null;

            try
            {
                content["over"] = true;
                content.gotoAndStop("menu");
                log("closed to menu");
            }
            catch (e6:Error)
            {
                log("goto menu err " + e6.message);
            }
        }

        private function resetDismissTimer():void
        {
            try
            {
                if (dismissTimer != null)
                {
                    dismissTimer.stop();
                    dismissTimer.start();
                }
            }
            catch (err:Error)
            {
            }
        }

        private function playerName():String
        {
            try
            {
                var ln:* = content["lastname"];
                if (ln != null && String(ln) != "" && String(ln) != "null" && String(ln) != "undefined")
                    return String(ln);
            }
            catch (err:Error)
            {
            }
            return DEFAULT_PLAYER;
        }

        private function describe(role:Array):String
        {
            var s:String = "";
            for (var i:int = 0; i < ROWS && i < role.length; i++)
            {
                var e:* = role[i];
                s += (e is Array ? String(e[0]) + "/" + String(e[1]) : "?") + " ";
            }
            return s;
        }

        private function seedRole(role:Array):void
        {
            for (var i:int = 0; i < ROWS; i++)
            {
                var ent:* = i < role.length ? role[i] : null;

                if (!(ent is Array))
                {
                    ent = [];
                    role[i] = ent;
                }

                if (ent[0] == null)
                    ent[0] = board[i].n;
                if (ent[1] == null)
                    ent[1] = board[i].s;
            }
        }

        // ------------------------------------------- the game's own name prompt

        private function watchNewRecord(role:Array):void
        {
            var gnew:Boolean = false;
            try
            {
                gnew = Boolean(content["getnew"]);
            }
            catch (err:Error)
            {
            }

            if (gnew && !prevGetnew && !promptShown)
            {
                log("NEW RECORD flagged, gsit=" + content["gsit"] + " role=" + describe(content["role"] as Array));
                showGameNameClip(role);
            }

            if (!gnew)
                promptShown = false;

            prevGetnew = gnew;
        }

        /**
         * The game's name-entry clip is placed on the timeline at x=-609 (off
         * screen) and nothing ever brings it in, because the code that used to
         * do it lived behind the dead DB callbacks. Move it to the centre and
         * jump to its setup frame (frame 6), which wires its own OK button.
         *
         * The name is NOT written here - it is written in applyName() from the
         * actual field text, so a player who edits the name gets their edit
         * saved (previously it was hard-coded to "CaPoo").
         */
        private function showGameNameClip(role:Array):void
        {
            if (promptShown)
                return;

            var clip:MovieClip = null;
            try
            {
                clip = content["new_name"] as MovieClip;
            }
            catch (err:Error)
            {
            }

            if (clip == null)
                clip = nameClip;

            if (clip == null)
            {
                log("new_name clip missing");
                return;
            }

            // the game may have created a fresh instance on a later pass -
            // park the old one so two panels can never be on screen at once
            if (nameClip != null && nameClip != clip)
            {
                try
                {
                    nameClip.visible = false;
                    nameClip.x = -609;
                }
                catch (err:Error)
                {
                }
            }

            var gsit:int = -1;
            try
            {
                gsit = int(content["gsit"]);
            }
            catch (err:Error)
            {
            }

            try
            {
                clip.gotoAndStop(6);
                clip.visible = true;

                var b:Rectangle = clip.getBounds(content);
                clip.x += 240 - (b.x + b.width / 2);
                clip.y += 400 - (b.y + b.height / 2);
                baseX = clip.x;
                baseY = clip.y;

                content.setChildIndex(clip, content.numChildren - 1);
                nameClip = clip;

                prepareNameField(clip);
                installOkHotspot(clip);

                // the soft keyboard is requested by prepareNameField(), and it
                // covers the lower part of the screen where the OK button is
                // -> lift the panel right away so OK always stays reachable
                applyKeyboardOffset(true);

                promptShown = true;
                promptGsit = gsit;

                log("NAME CLIP shown at " + clip.x + "," + clip.y
                    + " size " + clip.width + "x" + clip.height
                    + " gsit=" + gsit
                    + " default=" + (nameField != null ? nameField.text : "?"));

                // confirm paths: the game's own OK button (hotspot), the
                // soft-keyboard Done key, or the stage-level hit test
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageDown, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onNameKeyDown);

                // safety net: if the player does nothing, auto-save the
                // (possibly edited) name and return to the menu
                dismissTimer = new Timer(NAME_TIMEOUT_MS, 1);
                dismissTimer.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void
                {
                    log("auto-dismiss timer fired");
                    requestConfirm();
                });
                dismissTimer.start();
            }
            catch (err:Error)
            {
                log("NAME CLIP err " + err.message);
            }
        }

        // ------------------------------------------------------------- display

        private function syncDisplay(role:Array):void
        {
            var rows:Array = [];
            var i:int;

            for (i = 0; i < ROWS; i++)
            {
                var ent:* = i < role.length ? role[i] : null;
                var n:String = DEFAULT_NAME;
                var s:int = 0;

                if (ent is Array)
                {
                    if (ent[0] != null)
                        n = String(ent[0]);
                    if (ent[1] != null)
                    {
                        var raw:* = ent[1];
                        if (raw is Number)
                            s = int(raw);
                        else
                        {
                            // the game's go_again() wrote a name into the score
                            // slot -> move it back to the name slot
                            n = String(raw);
                            s = 0;
                        }
                    }
                }

                rows.push({n: n, s: s});
            }

            var view:Array = rows.slice();
            view.sortOn("s", Array.NUMERIC | Array.DESCENDING);

            var sig:String = "";
            for (i = 0; i < ROWS; i++)
            {
                sig += view[i].n + "|" + view[i].s + ";";
                setText("name" + (i + 1), view[i].n);
                setText("scr" + (i + 1), String(view[i].s));
            }

            setText("hit_point", String(view[0].s));

            if (sig != lastSig)
            {
                lastSig = sig;
                board = view;
                saveBoard();
            }
        }

        private function setText(field:String, value:String):void
        {
            try
            {
                var tf:* = content[field];
                if (tf is TextField && (tf as TextField).text != value)
                    (tf as TextField).text = value;
            }
            catch (err:Error)
            {
            }
        }

        private function scrubPlaceholders(root:DisplayObjectContainer):void
        {
            var i:int;

            for (i = 0; i < root.numChildren; i++)
            {
                var child:DisplayObject = root.getChildAt(i);

                if (child is TextField)
                {
                    var tf:TextField = child as TextField;
                    if (tf.text == "undefined" || tf.text == "null")
                        tf.text = "";
                }
                else if (child is DisplayObjectContainer)
                {
                    scrubPlaceholders(child as DisplayObjectContainer);
                }
            }
        }
    }
}
