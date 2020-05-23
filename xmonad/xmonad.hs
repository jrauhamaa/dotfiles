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

wallpaperDir = "/home/joppe/Pictures/wallpapers/"

getRandomIndex min max = do
    gen <- getStdGen
    let (index, newGen) = randomR (min, max) gen
        in return index

getWallpaperPath = do
    wallpapers <- listDirectory wallpaperDir
    index <- getRandomIndex 0 ((length wallpapers) - 1)
    return $ joinPath
        [ wallpaperDir
        , (wallpapers !! index)
        ]

myTerminal = "termite"

notificationTimeOut = 3
notify :: MonadIO m => String -> m ()
notify message =
    let command = "echo \""
                    ++ message
                    ++ "\" | dzen2 -p "
                    ++ show notificationTimeOut
    in spawn command

-- An ugly hack to only start redshift if not yet running. spawnOnce is not
-- suitable for this since it won't launch redshift after it has been stopped.
dayT          = 5000
nightT        = 3500
spawnRedshift = "[ -z $(pgrep redshift) ]"
                ++ " && redshift -t "
                ++ show dayT ++ "K:"
                ++ show nightT ++ "K"
killRedshift  = "pgrep redshift | xargs kill"

captureClipboard command = command
                           ++ " | xclip -selection clipboard -t image/png"
captureScreen    = captureClipboard "maim"
captureSelection = captureClipboard "maim -s"
captureWindow    = captureClipboard
                       ( "maim -i $("
                         ++ "xdotool getmouselocation | "
                         ++ "sed -re 's/.*window:([0-9]+)/\\1/'"
                         ++ ")" )

spotifySend     = "dbus-send"
                  ++ " --print-reply"
                  ++ " --dest=org.mpris.MediaPlayer2.spotify"
                  ++ " /org/mpris/MediaPlayer2"
                  ++ " org.mpris.MediaPlayer2.Player."
spotifyPlay     = spotifySend ++ "Play"
spotifyPause    = spotifySend ++ "Pause"
spotifyPrevious = spotifySend ++ "Previous"
spotifyNext     = spotifySend ++ "Next"

youtubeMpv      = "xclip -selection clipboard -o"
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

keyBindings =
    -- hotkeys for often used programs
    [ ( "M-f",           spawn "firefox" )
    , ( "M-s",           spawn "spotify" )
    , ( "M-<Up>",        spawn spotifyPlay)
    , ( "M-<Down>",      spawn spotifyPause)
    , ( "M-<Left>",      spawn spotifyPrevious)
    , ( "M-<Right>",     spawn spotifyNext)
    , ( "M-v",           spawn watchVideo)
    , ( "M-i",           spawn "qutebrowser" )
    , ( "M-x",           spawn "xterm" )
    , ( "M-n",           spawn $ myTerminal ++ " -e nnn" )
    , ( "M-y",           sendMessage $ ResizableTile.MirrorExpand )
    , ( "M-o",           sendMessage $ ResizableTile.MirrorShrink )
    , ( "M-S-l",         spawn "xscreensaver-command -lock" )
    , ( "M-r"
      , spawn spawnRedshift
        <+> notify "redshift: on"
      )
    , ( "M-S-r"
      , spawn killRedshift
        <+> notify "redshift: off"
      )
    ]
    ++
    [ let index = show i
      in ( "M-S-" ++ index
         , windows (StackSet.greedyView index . StackSet.shift index)
         )
      | i <- [1..9]
    ]

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
                    ++ "xbacklight"
                    ++ " | sed -re 's/\\.?0+$//g'"
                    ++ " | head -c 4"
                    ++ ")%"

controlKeys =
    -- volume keys
    [ ( (0, 0x1008FF11)
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
    -- brightness keys
    , ( (0, 0x1008FF02)
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

startUp wallpaperPath =
    spawn "picom -bcCGf"
        <+> (spawn $ "feh --bg-fill " ++ wallpaperPath)
        <+> (SpawnOnce.spawnOnce "xscreensaver -no-splash")

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
                          screen       = True
                          window       = True

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

-- allow easy toggling of fadeinactive
fade = True
getLogHook xmproc = if fade
                        then h <+> FadeInactive.fadeInactiveLogHook 0.9
                        else h
                        where h = workspaceLogHook xmproc

getConfig wallpaperPath xmproc = def
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
    , startupHook        = startUp wallpaperPath
    , layoutHook         = myLayoutHook
    , logHook            = getLogHook xmproc
    , manageHook         = doF StackSet.swapDown
    }
    `additionalKeysP`
    keyBindings
    `additionalKeys`
    controlKeys

-- Pretty print options
pp = Log.xmobarPP {
    Log.ppCurrent = Log.xmobarColor "#429942" ""
                        . Log.wrap "<" ">"
}

-- Key binding to toggle the status bar
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

main = do
    wallpaperPath <- getWallpaperPath
    xmproc        <- Run.spawnPipe "xmobar -d"
    let config = getConfig wallpaperPath xmproc
        in xmonad =<< Log.statusBar "xmobar" pp toggleStrutsKey config
