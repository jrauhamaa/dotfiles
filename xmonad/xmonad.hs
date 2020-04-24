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

keyBindings =
    -- hotkeys for often used programs
    [ ("M-f",           spawn "firefox")
    , ("M-s",           spawn "spotify")
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

configs = defaultConfig 
    -- appearance
    { borderWidth        = 1
    -- mouse config
    , clickJustFocuses   = False
    , focusFollowsMouse  = False
    -- basic functionality
    , modMask            = mod4Mask -- Use Super instead of Alt
    , terminal           = "termite"
    }
    `additionalKeysP`
    keyBindings
    `additionalKeys`
    controlKeys

-- Custom PP, configure it as you like. It determines what is being written to the bar.
pp = xmobarPP { ppCurrent = xmobarColor "#429942" "" . wrap "<" ">" }

-- Key binding to toggle the gap for the bar.
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

main = xmonad =<< statusBar "xmobar" pp toggleStrutsKey configs

