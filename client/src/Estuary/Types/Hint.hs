-- TODO: this should be moved/renamed as Estuary.Client.Hint

module Estuary.Types.Hint where

import Data.Text (Text)
import Data.Maybe (mapMaybe)

import Estuary.Types.Tempo
import Estuary.Utility
import Estuary.Types.Definition
import Estuary.Types.TranslatableText
import Estuary.Client.Settings
import Estuary.Types.View
import Estuary.Types.Request
import Estuary.Types.EnsembleOp

data Hint =
  SampleHint Text | -- TODO: supposed to cause preload of every sample in that bank, hasn't been reimplemented since new Resources system though (currently a no-op)
  LogMessage TranslatableText | -- message is printed in Estuary's terminal (response: Estuary.Widgets.Terminal)
  ChangeSettings (Settings -> Settings) | -- change Settings of local UI and rendering (response: settingsForWidgets in Estuary.Widgets.Estuary)
  RequestHint Request | -- directly issue a Request
  SetLocalView View


hintsToRequests :: [Hint] -> [Request]
hintsToRequests = mapMaybe f
  where f (RequestHint r) = Just r
        f _ = Nothing
