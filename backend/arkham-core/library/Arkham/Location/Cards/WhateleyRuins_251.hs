module Arkham.Location.Cards.WhateleyRuins_251 (
  whateleyRuins_251,
  WhateleyRuins_251 (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Game.Helpers
import Arkham.GameValue
import Arkham.Helpers.Enemy
import Arkham.Id
import Arkham.Location.Cards qualified as Cards (whateleyRuins_251)
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Scenarios.UndimensionedAndUnseen.Helpers
import Arkham.SkillType

newtype WhateleyRuins_251 = WhateleyRuins_251 LocationAttrs
  deriving anyclass (IsLocation)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

whateleyRuins_251 :: LocationCard WhateleyRuins_251
whateleyRuins_251 =
  location WhateleyRuins_251 Cards.whateleyRuins_251 2 (PerPlayer 2)

instance HasModifiersFor WhateleyRuins_251 where
  getModifiersFor (InvestigatorTarget iid) (WhateleyRuins_251 attrs) =
    pure $
      toModifiers
        attrs
        [SkillModifier SkillWillpower (-1) | iid `on` attrs]
  getModifiersFor _ _ = pure []

instance HasAbilities WhateleyRuins_251 where
  getAbilities (WhateleyRuins_251 attrs) =
    withBaseAbilities attrs $
      [ restrictedAbility attrs 1 Here (ActionAbility Nothing $ ActionCost 1)
      | locationRevealed attrs
      ]

instance RunMessage WhateleyRuins_251 where
  runMessage msg l@(WhateleyRuins_251 attrs) = case msg of
    UseCardAbility iid source 1 _ _
      | isSource attrs source ->
          l
            <$ push
              (beginSkillTest iid source (toTarget attrs) SkillIntellect 4)
    PassedSkillTest iid _ source SkillTestInitiatorTarget {} _ _
      | isSource attrs source -> do
          abominations <- getBroodOfYogSothoth
          abominationsWithLocation <- forToSnd abominations (selectJust . LocationWithEnemy . EnemyWithId)
          abominationsWithLocationAndAccessibleLocations
            :: [ ( EnemyId
                 , LocationId
                 , [LocationId]
                 )
               ] <-
            for abominationsWithLocation $ \(abomination, locationId) ->
              (abomination,locationId,)
                <$> getEnemyAccessibleLocations abomination

          push $
            chooseOne
              iid
              [ targetLabel
                eid
                [ chooseOne
                  iid
                  [targetLabel destination [EnemyMove eid destination]]
                | destination <- destinations
                ]
              | (eid, _, destinations) <-
                  abominationsWithLocationAndAccessibleLocations
              ]
          pure l
    _ -> WhateleyRuins_251 <$> runMessage msg attrs
