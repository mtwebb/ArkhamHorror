module Arkham.Types.Location.Cards.RialtoBridge
  ( rialtoBridge
  , RialtoBridge(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Location.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Direction
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message

newtype RialtoBridge = RialtoBridge LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rialtoBridge :: LocationCard RialtoBridge
rialtoBridge = locationWith
  RialtoBridge
  Cards.rialtoBridge
  2
  (Static 1)
  NoSymbol
  []
  (connectsToL .~ singleton RightOf)

instance HasModifiersFor env RialtoBridge

instance ActionRunner env => HasActions env RialtoBridge where
  getActions iid window (RialtoBridge attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env RialtoBridge where
  runMessage msg l@(RialtoBridge attrs) = case msg of
    MoveFrom iid lid | lid == toId attrs ->
      l <$ push (LoseActions iid (toSource attrs) 1)
    _ -> RialtoBridge <$> runMessage msg attrs