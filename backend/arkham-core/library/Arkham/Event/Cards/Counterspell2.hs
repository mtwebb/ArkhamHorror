module Arkham.Event.Cards.Counterspell2
  ( counterspell2
  , Counterspell2(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Message

newtype Counterspell2 = Counterspell2 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

counterspell2 :: EventCard Counterspell2
counterspell2 = event Counterspell2 Cards.counterspell2

instance RunMessage Counterspell2 where
  runMessage msg e@(Counterspell2 attrs) = case msg of
    InvestigatorPlayEvent _ eid _ _ _ | eid == toId attrs -> do
      e <$ pushAll [Discard (toTarget attrs)]
    _ -> Counterspell2 <$> runMessage msg attrs