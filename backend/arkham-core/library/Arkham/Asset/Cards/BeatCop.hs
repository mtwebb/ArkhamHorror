module Arkham.Asset.Cards.BeatCop (
  BeatCop (..),
  beatCop,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.DamageEffect
import Arkham.Matcher hiding (NonAttackDamageEffect)
import Arkham.SkillType

newtype BeatCop = BeatCop AssetAttrs
  deriving anyclass (IsAsset)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

beatCop :: AssetCard BeatCop
beatCop = ally BeatCop Cards.beatCop (2, 2)

instance HasModifiersFor BeatCop where
  getModifiersFor (InvestigatorTarget iid) (BeatCop a) =
    pure $ toModifiers a [SkillModifier SkillCombat 1 | controlledBy a iid]
  getModifiersFor _ _ = pure []

instance HasAbilities BeatCop where
  getAbilities (BeatCop x) =
    [ restrictedAbility
        x
        1
        (ControlsThis <> EnemyCriteria (EnemyExists $ EnemyAt YourLocation))
        $ FastAbility (DiscardCost FromPlay $ toTarget x)
    ]

instance RunMessage BeatCop where
  runMessage msg a@(BeatCop attrs) = case msg of
    InDiscard _ (UseCardAbility iid source 1 _ _) | isSource attrs source -> do
      enemies <- selectList (EnemyAt $ locationWithInvestigator iid)
      push $
        chooseOrRunOne
          iid
          [ targetLabel eid [EnemyDamage eid $ nonAttack source 1]
          | eid <- enemies
          ]
      pure a
    _ -> BeatCop <$> runMessage msg attrs
