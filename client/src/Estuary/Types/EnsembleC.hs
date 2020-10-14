{-# LANGUAGE OverloadedStrings #-}

-- The type EnsembleC represents the state of an Ensemble from the perspective
-- of the Estuary client (ie. the widgets/UI)

module Estuary.Types.EnsembleC where

import Data.Map.Strict as Map
import qualified Data.IntMap.Strict as IntMap
import Data.Time
import Data.Time.Clock.POSIX
import Data.Maybe
import Data.Text (Text)
import qualified Data.Text as T
import TextShow
import Control.Applicative
import Reflex

import Estuary.Types.Response
import Estuary.Types.EnsembleRequest
import Estuary.Types.EnsembleResponse
import Estuary.Types.Definition
import Estuary.Types.View
import Estuary.Types.View.Parser
import Estuary.Types.View.Presets
import qualified Estuary.Types.Terminal as Terminal
import Estuary.Types.Tempo
import Estuary.Types.Hint
import Estuary.Types.Tempo
import Estuary.Types.Participant

import Estuary.Types.Chat

-- each field of the EnsembleC record is Dynamic t a, so that any of them can
-- change independently without triggering computation related to the others.

data EnsembleC t = EnsembleC {
  ensembleName :: Dynamic t Text,
  tempo :: Dynamic t Tempo,
  zones :: Dynamic t (IntMap.IntMap Definition), -- refactor later to make individual zones Dynamic
  views :: Dynamic t (Map.Map Text View),
  chats :: Dynamic t [Chat],
  participants :: Dynamic t (Map.Map Text Participant),
  anonymousParticipants :: Dynamic t Int
  ensembleAudioMap :: Dynamic t AudioMap,
  userHandle :: Dynamic t Text, -- how the user appears to others in the ensemble; "" == anonymous
  location :: Dynamic t Text, -- the user's location (cached for re-authentication scenarios)
  password :: Dynamic t Text, -- the participant password (cached for re-authentication scenarios)
  view :: Dynamic t (Either View Text) -- Rights are from preset views, Lefts are local views
}

emptyEnsembleC :: UTCTime -> EnsembleC t
emptyEnsembleC t = EnsembleC {
  ensembleName = constDyn "",
  tempo = constDyn $ Tempo { time=t, count=0.0, freq=0.5 },
  zones = constDyn IntMap.empty,
  views = constDyn $ Map.empty,
  chats = constDyn [],
  participants = constDyn Map.empty,
  anonymousParticipants = constDyn 0,
  ensembleAudioMap = constDyn Map.empty,
  userHandle = constDyn "",
  location = constDyn "",
  password = constDyn "",
  view = constDyn $ Right "default"
  }


-- ** WORKING below here, continuing to refactor on the basis of the above

joinEnsembleC :: Text -> Text -> Text -> Text -> EnsembleC -> EnsembleC
joinEnsembleC eName uName loc pwd es = modifyEnsemble (\x -> x { ensembleName = eName } ) $ es {  userHandle = uName, Estuary.Types.EnsembleC.location = loc, Estuary.Types.EnsembleC.password = pwd, view = Right "default" }

leaveEnsembleC :: EnsembleC -> EnsembleC
leaveEnsembleC x = x {
  ensemble = leaveEnsemble (ensemble x),
  userHandle = "",
  Estuary.Types.EnsembleC.location = "",
  Estuary.Types.EnsembleC.password = ""
  }

-- if a specific named view is in the ensemble's map of views we get that
-- or if not but a view with that names is in Estuary's presets we get that
-- so ensembles can have a different default view than solo mode simply by
-- defining a view at the key "default"

inAnEnsemble :: EnsembleC -> Bool
inAnEnsemble e = ensembleName (ensemble e) /= ""

lookupView :: Text -> Ensemble -> Maybe View
lookupView t e = Map.lookup t (views e) <|> Map.lookup t presetViews

listViews :: Ensemble -> [Text]
listViews e = Map.keys $ Map.union (views e) presetViews

modifyEnsemble :: (Ensemble -> Ensemble) -> EnsembleC -> EnsembleC
modifyEnsemble f e = e { ensemble = f (ensemble e) }

activeView :: EnsembleC -> View
activeView e = either id f (view e)
  where f x = maybe EmptyView id $ lookupView x (ensemble e)

nameOfActiveView :: EnsembleC -> Text
nameOfActiveView e = either (const "(local view)") id $ view e

selectPresetView :: Text -> EnsembleC -> EnsembleC
selectPresetView t e = e { view = Right t }

selectLocalView :: View -> EnsembleC -> EnsembleC
selectLocalView v e = e { view = Left v }

-- replaceStandardView selects a standard view while also redefining it
-- according to the provided View argument. (To be used when a custom view is
-- republished as a standard view in an ensemble.)
replaceStandardView :: Text -> View -> EnsembleC -> EnsembleC
replaceStandardView t v e = e {
  ensemble = writeView t v (ensemble e),
  view = Right t
  }

commandToHint :: EnsembleC -> Terminal.Command -> Maybe Hint
commandToHint _ (Terminal.LocalView _) = Just $ LogMessage "local view changed"
commandToHint _ (Terminal.PresetView x) = Just $ LogMessage $ "preset view " <> x <> " selected"
commandToHint _ (Terminal.PublishView x) = Just $ LogMessage $ "active view published as " <> x
commandToHint es (Terminal.ActiveView) = Just $ LogMessage $ nameOfActiveView es
commandToHint es (Terminal.ListViews) = Just $ LogMessage $ showt $ listViews $ ensemble es
commandToHint es (Terminal.DumpView) = Just $ LogMessage $ dumpView (activeView es)
commandToHint _ (Terminal.Delay t) = Just $ SetGlobalDelayTime t
commandToHint es (Terminal.ShowTempo) = Just $ LogMessage $ T.pack $ show $ tempo $ ensemble es
commandToHint _ _ = Nothing

commandToStateChange :: Terminal.Command -> EnsembleC -> EnsembleC
commandToStateChange (Terminal.LocalView v) es = selectLocalView v es
commandToStateChange (Terminal.PresetView t) es = selectPresetView t es
commandToStateChange (Terminal.PublishView t) es = replaceStandardView t (activeView es) es
commandToStateChange _ es = es

requestToStateChange :: EnsembleRequest -> EnsembleC -> EnsembleC
requestToStateChange (WriteTempo x) es = modifyEnsemble (writeTempo x) es
requestToStateChange (WriteZone n v) es = modifyEnsemble (writeZone n v) es
requestToStateChange (WriteView t v) es = modifyEnsemble (writeView t v) es
requestToStateChange _ es = es
-- note: WriteChat and WriteStatus don't directly affect the EnsembleC and are thus
-- not matched here. Instead, the server responds to these requests to all participants
-- and in this way the information "comes back down" from the server.

ensembleResponseToStateChange :: EnsembleResponse -> EnsembleC -> EnsembleC
ensembleResponseToStateChange (TempoRcvd t) es = modifyEnsemble (writeTempo t) es
ensembleResponseToStateChange (ZoneRcvd n v) es = modifyEnsemble (writeZone n v) es
ensembleResponseToStateChange (ViewRcvd t v) es = modifyEnsemble (writeView t v) es
ensembleResponseToStateChange (ChatRcvd c) es = modifyEnsemble (appendChat c) es
ensembleResponseToStateChange (ParticipantJoins x) es = modifyEnsemble (writeParticipant (name x) x) es
ensembleResponseToStateChange (ParticipantUpdate x) es = modifyEnsemble (writeParticipant (name x) x) es
ensembleResponseToStateChange (ParticipantLeaves n) es = modifyEnsemble (deleteParticipant n) es
ensembleResponseToStateChange (AnonymousParticipants n) es = modifyEnsemble (writeAnonymousParticipants n) es
ensembleResponseToStateChange _ es = es

responseToStateChange :: Response -> EnsembleC -> EnsembleC
responseToStateChange (JoinedEnsemble eName uName loc pwd) es = joinEnsembleC eName uName loc pwd es
responseToStateChange _ es = es

commandToEnsembleRequest :: EnsembleC -> Terminal.Command -> Maybe (IO EnsembleRequest)
commandToEnsembleRequest es (Terminal.PublishView x) = Just $ return (WriteView x (activeView es))
commandToEnsembleRequest es (Terminal.Chat x) = Just $ return (WriteChat x)
commandToEnsembleRequest es Terminal.AncientTempo = Just $ return (WriteTempo x)
  where x = Tempo { freq = 0.5, time = UTCTime (fromGregorian 2020 01 01) 0, count = 0 }
commandToEnsembleRequest es (Terminal.SetCPS x) = Just $ do
  x' <- changeTempoNow (realToFrac x) (tempo $ ensemble es)
  return (WriteTempo x')
commandToEnsembleRequest es (Terminal.SetBPM x) = Just $ do
  x' <- changeTempoNow (realToFrac x / 240) (tempo $ ensemble es)
  return (WriteTempo x')
commandToEnsembleRequest _ _ = Nothing

responseToMessage :: Response -> Maybe Text
responseToMessage (ResponseError e) = Just $ "error: " <> e
responseToMessage (ResponseOK m) = Just m
responseToMessage (EnsembleResponse (ChatRcvd c)) = Just $ showChatMessage c
responseToMessage (EnsembleResponse (ParticipantJoins x)) = Just $ name x <> " has joined the ensemble"
responseToMessage (EnsembleResponse (ParticipantLeaves n)) = Just $ n <> " has left the ensemble"
-- the cases below are for debugging only and can be commented out when not debugging:
-- responseToMessage (TempoRcvd _) = Just $ "received new tempo"
-- responseToMessage (ZoneRcvd n _) = Just $ "received zone " <> showtl n
-- responseToMessage (ViewRcvd n _) = Just $ "received view " <> n
-- responseToMessage (ParticipantUpdate n _) = Just $ "received ParticipantUpdate about " <> n
-- responseToMessage (AnonymousParticipants n) = Just $ "now there are " <> showtl n <> " anonymous participants"
-- don't comment out the case below, of course!
responseToMessage _ = Nothing
