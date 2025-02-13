module Arkham.Treachery.Cards.CaptiveMind (
  captiveMind,
  CaptiveMind (..),
) where

import Arkham.Prelude

import Arkham.Classes
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id
import Arkham.Investigator.Types (Field (..))
import Arkham.Message
import Arkham.Projection
import Arkham.SkillTest.Runner
import Arkham.SkillType
import Arkham.Source
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype CaptiveMind = CaptiveMind TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

captiveMind :: TreacheryCard CaptiveMind
captiveMind = treachery CaptiveMind Cards.captiveMind

getSkillTestModifiedSkillValue :: SkillTest -> GameT Int
getSkillTestModifiedSkillValue st = do
  currentSkillValue <- getCurrentSkillValue st
  iconCount <- skillIconCount st
  pure $ max 0 (currentSkillValue + iconCount)

doDiscard :: InvestigatorId -> Source -> GameT ()
doDiscard iid source = do
  st <- fromJustNote "missing skill test" <$> getSkillTest
  n <- getSkillTestModifiedSkillValue st
  handCount <- fieldMap InvestigatorHand length iid
  let discardCount = max 0 (handCount - n)
  pushAll $ replicate discardCount $ toMessage $ chooseAndDiscardCard iid source

instance RunMessage CaptiveMind where
  runMessage msg t@(CaptiveMind attrs) = case msg of
    Revelation iid (isSource attrs -> True) -> do
      push $ RevelationSkillTest iid (toSource attrs) SkillWillpower 0
      pure t
    PassedSkillTest iid _ (isSource attrs -> True) SkillTestInitiatorTarget {} _ _ ->
      do
        doDiscard iid (toSource attrs)
        pure t
    FailedSkillTest iid _ (isSource attrs -> True) SkillTestInitiatorTarget {} _ _ ->
      do
        doDiscard iid (toSource attrs)
        pure t
    _ -> CaptiveMind <$> runMessage msg attrs
