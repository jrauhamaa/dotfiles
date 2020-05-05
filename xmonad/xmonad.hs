import System.IO
    ( hPutStrLn )
import System.Random
    ( randomR
    , getStdGen
    )
import System.Directory
    ( listDirectory )
import System.FilePath.Posix
    ( joinPath )
import System.Posix.Types
    ( ProcessID )

import XMonad
    -- config utils
    ( def
    , doF
    , sendMessage
    , spawn
    , windows
    , XConfig ( XConfig )
    , xmonad
    -- key bindings
    , modMask
    , mod4Mask
    , xK_b
    , xK_Print
    , shiftMask
    -- config vars
    , borderWidth
    , clickJustFocuses
    , focusedBorderColor
    , focusFollowsMouse
    , layoutHook
    , logHook
    , manageHook
    , normalBorderColor
    , startupHook
    , terminal
    -- operators
    , (<+>)
    , (|||)
    , (-->)
    , (.|.)
    -- types
    , MonadIO
    )
-- xmobar utils
import XMonad.Hooks.DynamicLog
    ( ppCurrent
    , ppOutput
    , dynamicLogWithPP
    , statusBar
    , wrap
    , xmobarColor
    , xmobarPP
    )
import XMonad.Hooks.FadeInactive
    ( fadeInactiveLogHook )

import qualified XMonad.Layout as Layout
import qualified XMonad.Layout.Gaps as Gaps
import XMonad.Layout.NoBorders
    ( smartBorders )
import XMonad.Layout.ResizableTile
    ( ResizableTall ( ResizableTall )
    , MirrorResize ( MirrorExpand, MirrorShrink )
    )
import XMonad.Layout.Spacing
    ( spacingRaw
    , Border ( Border )
    )

import XMonad.StackSet
    ( greedyView
    , shift
    , swapDown
    )
import XMonad.Util.SpawnOnce
    ( spawnOnce )
-- easier keybinding config utils
import XMonad.Util.EZConfig
    ( additionalKeys
    , additionalKeysP
    )
import XMonad.Util.Run
    ( spawnPipe )

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
sendNotification :: MonadIO m => String -> m ()
sendNotification message =
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

keyBindings =
    -- hotkeys for often used programs
    [ ( "M-f",           spawn "firefox" )
    , ( "M-s",           spawn "spotify" )
    , ( "M-i",           spawn "qutebrowser" )
    , ( "M-n",           spawn $ myTerminal ++ " -e nnn" )
    , ( "M-y",           sendMessage $ MirrorExpand )
    , ( "M-o",           sendMessage $ MirrorShrink )
    , ( "M-S-l",         spawn "xscreensaver-command -lock" )
    , ( "M-r"
      , spawn spawnRedshift
        <+> sendNotification "redshift: on"
      )
    , ( "M-S-r"
      , spawn killRedshift
        <+> sendNotification "redshift: off"
      )
    ]
    ++
    [ let index = show i
      in ( "M-S-" ++ index
         , windows (greedyView index . shift index)
         )
      | i <- [1..9]
    ]

-- Unfortunately, this seems to be the way to get volume level from amixer :(
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
         <+> sendNotification volumeMessage
      )
    , ( (0, 0x1008FF13)
      , spawn "amixer set Master unmute && amixer -q sset Master 2%+"
         <+> sendNotification volumeMessage
      )
    , ( (0, 0x1008FF12)
      , spawn "amixer set Master toggle"
        <+> sendNotification muteMessage
      )
    -- brightness keys
    , ( (0, 0x1008FF02)
      , spawn "xbacklight -inc 8"
        <+> sendNotification brightnessMessage
      )
    , ( (0, 0x1008FF03)
      , spawn "xbacklight -dec 8"
        <+> sendNotification brightnessMessage
      )
    , ( (0, xK_Print)
      , spawn captureScreen
        <+> sendNotification "screen copied to clipboard"
      )
    , ( (mod4Mask, xK_Print)
      , spawn captureSelection
        <+> sendNotification "select area to be copied to clipboard"
      )
    , ( (mod4Mask .|. shiftMask, xK_Print)
      , spawn captureWindow
        <+> sendNotification "window copied to clipboard"
      )
    ]

startUp wallpaperPath =
    spawn "picom -bcCGf"
        <+> (spawn $ "feh --bg-fill " ++ wallpaperPath)
        <+> (spawnOnce "xscreensaver -no-splash")

tallLayout = ResizableTall nMasters resizeDelta masterWidth slaveHeights
    where nMasters = 1
          resizeDelta = 1/10
          masterWidth = 1/2
          slaveHeights = [] -- default = 1

myLayoutHook = spacingRaw smart screenBorder screen windowBorder window
                $ smartBorders
                $ tallLayout
                    ||| Layout.Mirror tallLayout
                    ||| Layout.Full
                    where screenBorder = Border 3 3 3 3
                          windowBorder = Border 3 3 3 3
                          smart        = True
                          screen       = True
                          window       = True

-- A hack to extract part of string between brackets.
-- TODO: Find a proper way to do this
workspaceStringColor = "#78e1f5"
workspaceFormat = (("<fc=" ++ workspaceStringColor ++ ">") ++)
                  . (++ "]</fc>")
                  . takeWhile (/= ']')
                  . dropWhile (/= '[')
workspaceLogHook xmproc = dynamicLogWithPP $
                      xmobarPP {
                        ppOutput = (hPutStrLn xmproc) . workspaceFormat
                      }

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
    -- , logHook            = fadeInactiveLogHook 0.9
    , logHook            = workspaceLogHook xmproc <+> fadeInactiveLogHook 0.9
    , manageHook         = doF swapDown
    }
    `additionalKeysP`
    keyBindings
    `additionalKeys`
    controlKeys

-- Pretty print options
pp = xmobarPP { ppCurrent = xmobarColor "#429942" "" . wrap "<" ">" }

-- Key binding to toggle the status bar
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

main = do
    wallpaperPath <- getWallpaperPath
    xmproc        <- spawnPipe "xmobar -d"
    let config = getConfig wallpaperPath xmproc
        in xmonad =<< statusBar "xmobar" pp toggleStrutsKey config
