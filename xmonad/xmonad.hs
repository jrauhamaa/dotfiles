import System.Random
    ( randomR
    , getStdGen
    )
import System.Directory
    ( listDirectory )
import System.FilePath.Posix
    ( joinPath )

import XMonad
    -- config utils
    ( defaultConfig
    , spawn
    , XConfig(..)
    , xmonad
    -- key bindings
    , modMask
    , mod4Mask
    , xK_b
    -- config vars
    , borderWidth
    , clickJustFocuses
    , focusFollowsMouse
    , terminal
    )
-- xmobar utils
import XMonad.Hooks.DynamicLog
    ( ppCurrent
    , statusBar
    , wrap
    , xmobarColor
    , xmobarPP
    )
-- easier keybinding config utils
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

keyBindings =
    -- hotkeys for often used programs
    [ ("M-f",           spawn "firefox")
    , ("M-s",           spawn "spotify")
    , ("M-n",           spawn $ myTerminal ++ " -e nnn")
    ]
controlKeys =
    -- volume keys
    [ ((0, 0x1008FF11), spawn "amixer set Master unmute && amixer -q sset Master 2%-")
    , ((0, 0x1008FF13), spawn "amixer set Master unmute && amixer -q sset Master 2%+")
    , ((0, 0x1008FF12), spawn "amixer set Master toggle")
    -- brightness keys
    , ((0, 0x1008FF02), spawn "xbacklight -inc 8")
    , ((0, 0x1008FF03), spawn "xbacklight -dec 8")
    ]

getConfig wallpaperPath = defaultConfig
    -- appearance
    { borderWidth        = 1
    -- mouse config
    , clickJustFocuses   = False
    , focusFollowsMouse  = False
    -- basic functionality
    , modMask            = mod4Mask -- Use Super instead of Alt
    , terminal           = myTerminal
    , startupHook        = spawn $ "feh --bg-fill " ++ wallpaperPath
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
    let config = getConfig wallpaperPath
        in xmonad =<< statusBar "xmobar" pp toggleStrutsKey config
