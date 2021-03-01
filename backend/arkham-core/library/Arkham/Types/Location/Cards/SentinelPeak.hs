module Arkham.Types.Location.Cards.SentinelPeak
  ( sentinelPeak
  , SentinelPeak(..)
  ) where

import Arkham.Prelude

import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.LocationSymbol
import Arkham.Types.Message
import Arkham.Types.Name
import Arkham.Types.Trait

newtype SentinelPeak = SentinelPeak LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sentinelPeak :: SentinelPeak
sentinelPeak =
  SentinelPeak
    $ baseAttrs
        "02284"
        (Name "Sentinel Peak" Nothing)
        EncounterSet.WhereDoomAwaits
        4
        (PerPlayer 2)
        Diamond
        [Square]
        [Dunwich, SentinelHill]
    & (costToEnterUnrevealedL
      .~ Costs [ActionCost 1, GroupClueCost (PerPlayer 2) Nothing]
      )
    & (victoryL ?~ 2)

instance HasModifiersFor env SentinelPeak where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env SentinelPeak where
  getActions iid window (SentinelPeak attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env SentinelPeak where
  runMessage msg l@(SentinelPeak attrs) = case msg of
    InvestigatorDrewEncounterCard iid card | iid `on` attrs -> l <$ when
      (Hex `member` ecTraits card)
      (unshiftMessage $ TargetLabel
        (toTarget attrs)
        [InvestigatorAssignDamage iid (toSource attrs) DamageAny 1 0]
      )
    InvestigatorDrewPlayerCard iid card | iid `on` attrs -> l <$ when
      (Hex `member` pcTraits card)
      (unshiftMessage $ TargetLabel
        (toTarget attrs)
        [InvestigatorAssignDamage iid (toSource attrs) DamageAny 1 0]
      )
    _ -> SentinelPeak <$> runMessage msg attrs