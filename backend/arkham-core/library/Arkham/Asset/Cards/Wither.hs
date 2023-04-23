module Arkham.Asset.Cards.Wither
  ( wither
  , witherEffect
  , Wither(..)
  )
where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Effect.Runner ()
import Arkham.Effect.Types
import Arkham.Effect.Window
import Arkham.EffectMetadata
import Arkham.SkillType
import Arkham.Source
import Arkham.Token
import Arkham.Window qualified as Window

newtype Wither = Wither AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wither :: AssetCard Wither
wither = asset Wither Cards.wither

instance HasAbilities Wither where
  getAbilities (Wither a) =
    [ restrictedAbility a 1 ControlsThis $ ActionAbilityWithSkill
        (Just Action.Fight)
        SkillWillpower
        (ActionCost 1)
    ]

instance RunMessage Wither where
  runMessage msg a@(Wither attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> a <$ pushAll
      [ createCardEffect Cards.wither Nothing source (InvestigatorTarget iid)
      , ChooseFightEnemy iid source Nothing SkillWillpower mempty False
      ]
    _ -> Wither <$> runMessage msg attrs

newtype WitherEffect = WitherEffect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

witherEffect :: EffectArgs -> WitherEffect
witherEffect = cardEffect WitherEffect Cards.wither

instance RunMessage WitherEffect where
  runMessage msg e@(WitherEffect attrs@EffectAttrs {..}) = case msg of
    RevealToken _ iid token | InvestigatorTarget iid == effectTarget -> do
      enemyId <- fromJustNote "no attacked enemy" <$> getAttackedEnemy
      when
        (tokenFace token `elem` [Skull, Cultist, Tablet, ElderThing])
        (pushAll
          [ If
            (Window.RevealTokenEffect iid token effectId)
            [CreateWindowModifierEffect EffectTurnWindow (EffectModifiers $ toModifiers attrs [EnemyFightWithMin (-1) (Min 1), EnemyEvadeWithMin (-1) (Min 1)]) (AbilitySource effectSource 1) (toTarget enemyId)]
          , DisableEffect effectId
          ]
        )
      pure e
    SkillTestEnds _ _ -> e <$ push (DisableEffect effectId)
    _ -> WitherEffect <$> runMessage msg attrs