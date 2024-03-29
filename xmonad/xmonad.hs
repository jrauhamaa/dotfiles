import System.IO
import System.Random
import System.Directory
import System.FilePath.Posix
import System.Posix.Types

import XMonad

-- xmobar utils
import qualified XMonad.Hooks.DynamicLog as Log
import qualified XMonad.Hooks.FadeInactive as FadeInactive

-- xmonad utils
import qualified XMonad.Layout as Layout
import qualified XMonad.Layout.NoBorders as NoBorders
import qualified XMonad.Layout.ResizableTile as ResizableTile
import qualified XMonad.Layout.Spacing as Spacing
import qualified XMonad.StackSet as StackSet
import qualified XMonad.Util.Run as Run
import qualified XMonad.Util.SpawnOnce as SpawnOnce
-- easier keybindings
import XMonad.Util.EZConfig
    ( additionalKeys
    , additionalKeysP
    )



------------------
-- NOTIFICAIONS --
------------------

notificationTimeOut = 3
notify :: MonadIO m => String -> m ()
notify message =
    let command = "echo \"" ++ message ++ "\""
                  ++ " | dzen2 -p " ++ show notificationTimeOut
    in spawn command

-- Unfortunately, this seems to be the way to get volume level pulse :(
volumeMessage = "Volume: $("
                ++ "sleep 0.1 && " -- wait for the volume change to apply
                ++ "pactl list sinks"
                ++ " | awk -F'/' '/Volume: front/  { print $4 }'"
                ++ ")"

muteMessage   = "Audio: $("
                ++ "sleep 0.1 && "
                ++ "pactl list sinks" -- wait for the changes to apply
                ++ " | awk '/Mute: / { print $2 } '"
                ++ " | sed -e 's/yes/muted/' -e 's/no/unmuted/'"
                ++ ")"

brightnessMessage = "Brightness: $("
                    ++ "sleep 0.1 && "
                    ++ "xbacklight -get"
                    ++ ")%"

--------------
-- REDSHIFT --
--------------

-- Use an ugly hack to only start redshift if not yet running. spawnOnce is not
-- suitable for this since it won't launch redshift after it has been stopped.
-- Geoclue sometimes fail to respond. Use hardcoded coordinates of Helsinki
-- instead.
latitude      = 60.17
longitude     = 24.93

dayT          = 5000
nightT        = 3500
spawnRedshift = "[ -z $(pgrep redshift) ]"
                ++ " && redshift"
                ++ " -t " ++ show dayT ++ "K:" ++ show nightT ++ "K"
                ++ " -l " ++ show latitude ++ ":" ++ show longitude
killRedshift  = "pgrep redshift | xargs kill"

----------------
-- SCREENSHOT --
----------------

captureClipboard command = command
                           ++ " | xclip -selection clipboard -t image/png"
captureScreen    = captureClipboard "maim -u"
captureSelection = captureClipboard "maim -s -u"
captureWindow    = captureClipboard
                       ( "maim -u -i $("
                         ++ "xdotool getmouselocation | "
                         ++ "sed -re 's/.*window:([0-9]+)/\\1/'"
                         ++ ")" )

------------
-- VIDEOS --
------------

youtubeMpv      = "xclip -selection clipboard -o"
                  ++ " | sed -e 's/&.*//'"
                  ++ " | xargs youtube-dl -o -"
                  ++ " | mpv -"

areenaMpv       = "xclip -selection clipboard -o"
                  ++ " | xargs yle-dl --pipe"
                  ++ " | mpv -"

watchVideo      = "case $(xclip -selection clipboard -o) in"
                  ++ " *areena.yle.fi*)"
                  ++ areenaMpv ++ ";;"
                  ++ " *youtube.com*|*youtu.be*)"
                  ++ youtubeMpv ++ ";;"
                  ++ " esac"

------------
-- XMOBAR --
------------

-- A hack to extract part of string between brackets.
-- TODO: Find a proper way to do this
workspaceStringColor = "lightgray"
workspaceFormat = (("<fc=" ++ workspaceStringColor ++ ">") ++)
                  . (++ "]</fc>")
                  . takeWhile (/= ']')
                  . dropWhile (/= '[')
workspaceLogHook xmproc = Log.dynamicLogWithPP $
                      Log.xmobarPP {
                        Log.ppOutput = (hPutStrLn xmproc) . workspaceFormat
                      }

-- Pretty print options
pp = Log.xmobarPP {
    Log.ppCurrent = Log.xmobarColor "#429942" ""
                        . Log.wrap "<" ">"
}

-----------------
-- KEYBINDINGS --
-----------------

myTerminal = "alacritty"

keyBindings =
    -- hotkeys for often used programs
    [ ( "M-f",              spawn "firefox" )
    , ( "M-s",              spawn "spotify" )
    , ( "M-<Up>",           spawn "playerctl play" )
    , ( "M-<Down>",         spawn "playerctl pause" )
    , ( "M-<Left>",         spawn "playerctl previous" )
    , ( "<XF86AudioPrev>",  spawn "playerctl previous" )
    , ( "M-<Right>",        spawn "playerctl next" )
    , ( "<XF86AudioNext>",  spawn "playerctl next" )
    , ( "M-v",              spawn watchVideo)
    , ( "M-i",              spawn "qutebrowser" )
    , ( "M-d",              spawn "discord" )
    -- discord will keep running as a background process and needs to be killed this way
    -- won't work unless killall is called twice
    , ( "M-S-d",            spawn "killall Discord && killall Discord" )
    , ( "M-x",              spawn "xterm" )
    , ( "M-n",              spawn $ myTerminal ++ " -e nnn" )
    , ( "M-y",              sendMessage $ ResizableTile.MirrorExpand )
    , ( "M-o",              sendMessage $ ResizableTile.MirrorShrink )
    , ( "M-S-l",            spawn "slock" )
    , ( "M-m",              spawn "signal-desktop" )
    , ( "M-e",              spawn "element-desktop" )
    , ( "M-S-e",            spawn "ps aux | grep app.asar | grep electron | head -2 | tr -s ' ' | cut -f2 -d' ' | xargs kill" )
    , ( "M-S-m",            spawn "telegram-desktop" )
    , ( "M-S-w",            spawn $ "feh --bg-fill --randomize " ++ wallPaperDir )
    , ( "M-r"
      , spawn spawnRedshift
        <+> notify "redshift: on"
      )
    , ( "M-S-r"
      , spawn killRedshift
        <+> notify "redshift: off"
      )
    , ( "<XF86AudioMute>"
      , spawn "amixer set Master toggle" <+> notify muteMessage
      )
    , ( "<XF86AudioLowerVolume>"
      , spawn "amixer set Master unmute && amixer -q sset Master 2%-"
        <+> notify volumeMessage
      )
    , ( "<XF86AudioRaiseVolume>"
      , spawn "amixer set Master unmute && amixer -q sset Master 2%+"
        <+> notify volumeMessage
      )
    ]
    ++
    [ let index = show i
      in ( "M-S-" ++ index
         , windows (StackSet.greedyView index . StackSet.shift index)
         )
      | i <- [1..9]
    ]

controlKeys =
    -- volume keys
    [
    {-
      ( (0, 0x1008FF11)
      , spawn "amixer set Master unmute && amixer -q sset Master 2%-"
        <+> notify volumeMessage
      )
    , ( (0, 0x1008FF13)
      , spawn "amixer set Master unmute && amixer -q sset Master 2%+"
        <+> notify volumeMessage
      )
    , ( (0, 0x1008FF12)
      , spawn "amixer set Master toggle"
        <+> notify muteMessage
      )
    -}
    -- brightness keys
      ( (0, 0x1008FF02)
      , spawn "xbacklight -inc 8"
        <+> notify brightnessMessage
      )
    , ( (0, 0x1008FF03)
      , spawn "xbacklight -dec 8"
        <+> notify brightnessMessage
      )
    , ( (0, xK_Print)
      , spawn captureScreen
        <+> notify "screen copied to clipboard"
      )
    , ( (mod4Mask, xK_Print)
      , spawn captureSelection
        <+> notify "select area to be copied to clipboard"
      )
    , ( (mod4Mask .|. shiftMask, xK_Print)
      , spawn captureWindow
        <+> notify "window copied to clipboard"
      )
    ]

-- Key binding to toggle the status bar
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

------------
-- LAYOUT --
------------

tallLayout = ResizableTile.ResizableTall nMasters
                                         resizeDelta
                                         masterWidth
                                         slaveHeights
    where nMasters = 1
          resizeDelta = 1/10
          masterWidth = 1/2
          slaveHeights = [] -- default = 1

myLayoutHook = Spacing.spacingRaw smart screenBorder screen windowBorder window
                $ NoBorders.smartBorders
                $ tallLayout
                    ||| Layout.Mirror tallLayout
                    ||| Layout.Full
                    where screenBorder = Spacing.Border 3 3 3 3
                          windowBorder = Spacing.Border 3 3 3 3
                          smart        = True
                          screen       = False
                          window       = False

-- allow easy toggling of fadeinactive
fade = False
getLogHook xmproc = if fade
                        then h <+> FadeInactive.fadeInactiveLogHook 0.9
                        else h
                        where h = workspaceLogHook xmproc

-----------------
-- MAIN CONFIG --
-----------------

wallPaperDir = "/home/joppe/Pictures/wallpapers/"

onStartUp =
    spawn "picom -bcCGf"
        <+> ( spawn $ "feh --bg-fill --randomize " ++ wallPaperDir )
        <+> ( SpawnOnce.spawnOnce $ "xautolock"
                                    ++ " -time 10"
                                    -- disable screenlock when mouse in
                                    -- top-right corner
                                    ++ " -corners 0-00"
                                    ++ " -locker slock" )

getConfig xmproc = def
    -- appearance
    { borderWidth        = 1
    , normalBorderColor  = "#151515"
    , focusedBorderColor = "#ffffff"
    -- mouse config
    , clickJustFocuses   = False
    , focusFollowsMouse  = False
    -- basic functionality
    , modMask            = mod4Mask -- Use Super instead of Alt
    , terminal           = myTerminal
    , startupHook        = onStartUp
    , layoutHook         = myLayoutHook
    , logHook            = getLogHook xmproc
    , manageHook         = doF StackSet.swapDown
    }
    `additionalKeysP`
    keyBindings
    `additionalKeys`
    controlKeys

main = do
    xmproc <- Run.spawnPipe "xmobar -d"
    let config = getConfig xmproc
        in xmonad =<< Log.statusBar "xmobar" pp toggleStrutsKey config
