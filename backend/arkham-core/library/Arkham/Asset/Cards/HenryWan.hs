module Arkham.Asset.Cards.HenryWan (
  henryWan,
  HenryWan (..),
) where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.ChaosBag.RevealStrategy
import Arkham.ChaosToken
import Arkham.Matcher
import Arkham.Prelude
import Arkham.RequestedChaosTokenStrategy

newtype Metadata = Metadata {revealedChaosTokens :: [ChaosToken]}
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

newtype HenryWan = HenryWan (AssetAttrs `With` Metadata)
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

henryWan :: AssetCard HenryWan
henryWan = ally (HenryWan . (`with` Metadata [])) Cards.henryWan (1, 2)

instance HasAbilities HenryWan where
  getAbilities (HenryWan (a `With` _)) =
    [ restrictedAbility a 1 ControlsThis $
        ActionAbility Nothing $
          ActionCost 1 <> ExhaustCost (toTarget a)
    ]

instance RunMessage HenryWan where
  runMessage msg a@(HenryWan (attrs `With` meta)) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $ RequestChaosTokens (toSource attrs) (Just iid) (Reveal 1) SetAside
      pure a
    RequestedChaosTokens (isSource attrs -> True) (Just iid) tokens -> do
      if any ((`elem` [Skull, Cultist, Tablet, ElderThing, AutoFail]) . chaosTokenFace) tokens
        then push $ chooseOne iid [Label "Do nothing" [HandleTargetChoice iid (toSource attrs) (toTarget attrs)]]
        else
          push $
            chooseOne
              iid
              [ Label "Stop" [HandleTargetChoice iid (toSource attrs) (toTarget attrs)]
              , Label "Draw Another" [RequestChaosTokens (toSource attrs) (Just iid) (Reveal 1) SetAside]
              ]
      pure $ HenryWan (attrs `with` Metadata (tokens <> revealedChaosTokens meta))
    HandleTargetChoice iid (isSource attrs -> True) _ -> do
      push $ ResetChaosTokens (toSource attrs)
      unless
        ( any
            ((`elem` [Skull, Cultist, Tablet, ElderThing, AutoFail]) . chaosTokenFace)
            (revealedChaosTokens meta)
        )
        $ do
          canDraw <- iid <=~> InvestigatorCanDrawCards Anyone
          canGainResources <- iid <=~> InvestigatorCanGainResources
          when (canDraw || canGainResources) $ do
            msgs <- for (revealedChaosTokens meta) $ \_ -> do
              drawing <- drawCards iid attrs 1
              pure $
                chooseOrRunOne iid $
                  [Label "Draw 1 card" [drawing] | canDraw]
                    <> [Label "Gain 1 resources" [TakeResources iid 1 (toSource attrs) False] | canGainResources]
            pushAll msgs
      pure $ HenryWan (attrs `with` Metadata [])
    _ -> HenryWan . (`with` meta) <$> runMessage msg attrs
