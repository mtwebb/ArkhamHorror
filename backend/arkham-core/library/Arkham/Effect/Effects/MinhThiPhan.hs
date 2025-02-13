module Arkham.Effect.Effects.MinhThiPhan (
  minhThiPhan,
  MinhThiPhan (..),
) where

import Arkham.Prelude

import Arkham.ChaosToken
import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Game.Helpers
import Arkham.Message
import Arkham.SkillType

newtype MinhThiPhan = MinhThiPhan EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

minhThiPhan :: EffectArgs -> MinhThiPhan
minhThiPhan = MinhThiPhan . uncurry4 (baseAttrs "03002")

instance HasModifiersFor MinhThiPhan where
  getModifiersFor target@(CardIdTarget _) (MinhThiPhan attrs) | effectTarget attrs == target = do
    pure $ toModifiers attrs [AddSkillIcons [WildIcon]]
  getModifiersFor target@(SkillTarget _) (MinhThiPhan attrs) | effectTarget attrs == target = do
    pure $ toModifiers attrs [ReturnToHandAfterTest]
  getModifiersFor _ _ = pure []

instance RunMessage MinhThiPhan where
  runMessage msg e@(MinhThiPhan attrs) = case msg of
    SkillTestEnds _ _ | effectSource attrs == ChaosTokenEffectSource ElderSign -> do
      case effectMetadata attrs of
        Just (EffectMessages msgs) ->
          pushAll (DisableEffect (effectId attrs) : msgs)
        _ -> push (DisableEffect $ effectId attrs)
      pure e
    SkillTestEnds _ _ -> e <$ push (DisableEffect $ effectId attrs)
    _ -> MinhThiPhan <$> runMessage msg attrs
