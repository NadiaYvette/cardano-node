{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE StandaloneDeriving #-}

module Cardano.Benchmarking.Script.Setters
where

import           Prelude
import           GHC.Generics
import           Data.Constraint.Extras.TH (deriveArgDict)
import           Data.Dependent.Sum (DSum(..) , (==>) )
import           Data.GADT.Compare.TH (deriveGCompare, deriveGEq)
import           Data.GADT.Show.TH (deriveGShow)

import           Cardano.Api (SlotNo, NetworkId)

-- Some boiler plate; ToDo may generate this.
data Tag v where
  TTTL                  :: Tag SlotNo
  TLocalSocket          :: Tag String
  TNetworkId            :: Tag NetworkId

deriveGEq ''Tag
deriveGCompare ''Tag
deriveGShow ''Tag
deriveArgDict ''Tag

deriving instance Show (Tag v)
deriving instance Eq (Tag v)

data Sum where
  STTL                  :: !SlotNo               -> Sum
  SLocalSocket          :: !String               -> Sum
  SNetworkId            :: !NetworkId            -> Sum
  deriving (Eq, Show, Generic)

taggedToSum :: Applicative f => DSum Tag f -> f Sum
taggedToSum x = case x of
  (TTTL                  :=> v) -> STTL                  <$> v
  (TLocalSocket          :=> v) -> SLocalSocket          <$> v
  (TNetworkId            :=> v) -> SNetworkId            <$> v

sumToTagged :: Applicative f => Sum -> DSum Tag f
sumToTagged x = case x of
  STTL                  v -> TTTL                  ==> v
  SLocalSocket          v -> TLocalSocket          ==> v
  SNetworkId            v -> TNetworkId            ==> v
