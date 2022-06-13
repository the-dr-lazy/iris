{-# LANGUAGE FlexibleContexts #-}

{- |
Module                  : Iris.Env
Copyright               : (c) 2022 Dmitrii Kovanikov
SPDX-License-Identifier : MPL-2.0
Maintainer              : Dmitrii Kovanikov <kovanikov@gmail.com>
Stability               : Experimental
Portability             : Portable

Environment of a CLI app.

@since 0.0.0.0
-}


module Iris.Env
    ( -- * Settings for the CLI app
      CliEnvSettings (..)
    , defaultCliEnvSettings

      -- * CLI application environment
      -- ** Constructing
    , CliEnv (..)
    , mkCliEnv
      -- ** Querying
    , asksCliEnv
    , asksAppEnv
    ) where

import Control.Monad.Reader (MonadReader, asks)
import Data.Kind (Type)
import System.IO (stderr, stdout)

import Iris.Cli.Version (VersionSettings, mkVersionParser)
import Iris.Colour.Mode (ColourMode, handleColourMode)

import qualified Options.Applicative as Opt


{- |

@since 0.0.0.0
-}
data CliEnvSettings (cmd :: Type) (appEnv :: Type) = CliEnvSettings
    {  -- | @since 0.0.0.0
      cliEnvSettingsCmdParser       :: Opt.Parser cmd

      -- | @since 0.0.0.0
    , cliEnvSettingsAppEnv          :: appEnv

      -- | @since 0.0.0.0
    , cliEnvSettingsHeaderDesc      :: String

      -- | @since 0.0.0.0
    , cliEnvSettingsProgDesc        :: String

      -- | @since 0.0.0.0
    , cliEnvSettingsVersionSettings :: Maybe VersionSettings
    }


{- |

@since 0.0.0.0
-}
defaultCliEnvSettings :: CliEnvSettings () ()
defaultCliEnvSettings = CliEnvSettings
    { cliEnvSettingsCmdParser       = pure ()
    , cliEnvSettingsAppEnv          = ()
    , cliEnvSettingsHeaderDesc      = "Simple CLI program"
    , cliEnvSettingsProgDesc        = "CLI tool build with iris - a Haskell CLI framework"
    , cliEnvSettingsVersionSettings = Nothing
    }


{- | CLI application environment. It contains default settings for
every CLI app and parameter

Has the following type parameters:

* @cmd@ — application commands
* @appEnv@ — application-specific environment; use @()@ if you don't
  have custom app environment

@since 0.0.0.0
-}
data CliEnv (cmd :: Type) (appEnv :: Type) = CliEnv
    { -- | @since 0.0.0.0
      cliEnvCmd              :: cmd

      -- | @since 0.0.0.0
    , cliEnvStdoutColourMode :: ColourMode

      -- | @since 0.0.0.0
    , cliEnvStderrColourMode :: ColourMode

      -- | @since 0.0.0.0
    , cliEnvAppEnv           :: appEnv
    }

{- |

@since 0.0.0.0
-}
mkCliEnv
    :: forall cmd appEnv
    .  CliEnvSettings cmd appEnv
    -> IO (CliEnv cmd appEnv)
mkCliEnv CliEnvSettings{..} = do
    cmd <- Opt.execParser cmdParserInfo
    stdoutColourMode <- handleColourMode stdout
    stderrColourMode <- handleColourMode stderr

    pure CliEnv
        { cliEnvCmd              = cmd
        , cliEnvStdoutColourMode = stdoutColourMode
        , cliEnvStderrColourMode = stderrColourMode
        , cliEnvAppEnv           = cliEnvSettingsAppEnv
        }
  where
    cmdParserInfo :: Opt.ParserInfo cmd
    cmdParserInfo = Opt.info
        ( Opt.helper
        <*> mkVersionParser cliEnvSettingsVersionSettings
        <*> cliEnvSettingsCmdParser
        )
        $ mconcat
            [ Opt.fullDesc
            , Opt.header cliEnvSettingsHeaderDesc
            , Opt.progDesc cliEnvSettingsProgDesc
            ]

{- | Get a field from the global environment 'CliEnv'.

@since 0.0.0.0
-}
asksCliEnv
    :: MonadReader (CliEnv cmd appEnv) m
    => (CliEnv cmd appEnv -> field)
    -> m field
asksCliEnv = asks

{- | Get a field from custom application-specific environment
@appEnv@.

@since 0.0.0.0
-}
asksAppEnv
    :: MonadReader (CliEnv cmd appEnv) m
    => (appEnv -> field)
    -> m field
asksAppEnv getField = asksCliEnv (getField . cliEnvAppEnv)
