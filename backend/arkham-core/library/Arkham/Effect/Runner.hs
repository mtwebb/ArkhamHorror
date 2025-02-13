{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.Effect.Runner (module X) where

import Arkham.Prelude

import Arkham.Effect.Types as X
import Arkham.Effect.Window as X
import Arkham.EffectMetadata as X
import Arkham.Helpers.SkillTest as X
import Arkham.Source as X
import Arkham.Target as X

import Arkham.Card
import Arkham.Classes.HasQueue
import Arkham.Classes.RunMessage
import Arkham.Message

instance RunMessage EffectAttrs where
  runMessage msg a@EffectAttrs {..} = case msg of
    EndSetup | isEndOfWindow a EffectSetupWindow -> do
      a <$ push (DisableEffect effectId)
    EndPhase | isEndOfWindow a EffectPhaseWindow -> do
      a <$ push (DisableEffect effectId)
    EndTurn _ | isEndOfWindow a EffectTurnWindow -> do
      a <$ push (DisableEffect effectId)
    EndRound | isEndOfWindow a EffectRoundWindow -> do
      a <$ push (DisableEffect effectId)
    FinishedEvent _ | isEndOfWindow a EffectEventWindow -> do
      a <$ push (DisableEffect effectId)
    BeginAction | isEndOfWindow a EffectNextActionWindow -> do
      a <$ push (DisableEffect effectId)
    SkillTestEnds _ _ | isEndOfWindow a EffectSkillTestWindow -> do
      a <$ push (DisableEffect effectId)
    CancelSkillEffects -> case effectSource of
      (SkillSource _) -> a <$ push (DisableEffect effectId)
      _ -> pure a
    PaidCost {} | isEndOfWindow a EffectCostWindow -> do
      a <$ push (DisableEffect effectId)
    PayCostFinished {} | isEndOfWindow a EffectCostWindow -> do
      a <$ push (DisableEffect effectId)
    PlayCard _ card _ _ _ | isEndOfWindow a (EffectCardCostWindow $ toCardId card) -> do
      a <$ push (DisableEffect effectId)
    After (PerformEnemyAttack {}) | isEndOfWindow a EffectAttackWindow -> do
      a <$ push (DisableEffect effectId)
    After (ResolvedCard _ _) | isEndOfWindow a EffectCardResolutionWindow -> do
      a <$ push (DisableEffect effectId)
    _ -> pure a
