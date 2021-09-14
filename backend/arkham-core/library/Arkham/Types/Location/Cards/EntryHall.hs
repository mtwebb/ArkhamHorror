module Arkham.Types.Location.Cards.EntryHall
  ( entryHall
  , EntryHall(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Trait

newtype EntryHall = EntryHall LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

entryHall :: LocationCard EntryHall
entryHall = locationWith
  EntryHall
  Cards.entryHall
  2
  (Static 0)
  Square
  [Circle]
  ((connectedTraitsL .~ singleton GroundFloor)
  . (revealedConnectedTraitsL .~ singleton GroundFloor)
  )

instance HasAbilities EntryHall where
  getAbilities (EntryHall attrs) = withResignAction attrs []

instance LocationRunner env => RunMessage env EntryHall where
  runMessage msg (EntryHall attrs) = EntryHall <$> runMessage msg attrs