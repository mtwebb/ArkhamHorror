module Arkham.Event.Cards.EmergencyCache (
  emergencyCache,
  EmergencyCache (..),
) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Message

newtype EmergencyCache = EmergencyCache EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

emergencyCache :: EventCard EmergencyCache
emergencyCache = event EmergencyCache Cards.emergencyCache

instance RunMessage EmergencyCache where
  runMessage msg e@(EmergencyCache attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ _ _
      | eid == eventId ->
          e <$ pushAll [TakeResources iid 3 (toSource attrs) False]
    _ -> EmergencyCache <$> runMessage msg attrs
