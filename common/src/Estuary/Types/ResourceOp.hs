{-# LANGUAGE DeriveGeneric, OverloadedStrings #-}

module Estuary.Types.ResourceOp where

import Data.Text
import GHC.Generics
import Data.Aeson
import Data.Sequence

import Estuary.Types.ResourceType
import Estuary.Types.Location

data ResourceOp =
  InsertResource ResourceType Text Location | -- Text is URL
  AppendResource ResourceType Text Text | -- first Text is URL, second Text is bankName
  DeleteResource ResourceType Location |
  ResourceListURL Text
  deriving (Show,Generic)

instance ToJSON ResourceOp where
  toEncoding = genericToEncoding defaultOptions
instance FromJSON ResourceOp

defaultResourceOps :: Seq ResourceOp
defaultResourceOps = Data.Sequence.singleton $ ResourceListURL "samples/resources.json"