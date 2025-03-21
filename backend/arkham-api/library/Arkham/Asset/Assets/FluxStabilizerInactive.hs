module Arkham.Asset.Assets.FluxStabilizerInactive (fluxStabilizerInactive) where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Card
import Arkham.Event.Cards qualified as Events
import Arkham.Helpers.Investigator (searchBonded)
import Arkham.Matcher
import Arkham.Message.Lifted.Choose
import Arkham.Token

newtype FluxStabilizerInactive = FluxStabilizerInactive AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fluxStabilizerInactive :: AssetCard FluxStabilizerInactive
fluxStabilizerInactive = asset FluxStabilizerInactive Cards.fluxStabilizerInactive

instance HasAbilities FluxStabilizerInactive where
  getAbilities (FluxStabilizerInactive x) =
    [restricted x 1 ControlsThis $ forced $ PlacedToken #after AnySource (TargetIs $ toTarget x) Clue]

instance RunMessage FluxStabilizerInactive where
  runMessage msg a@(FluxStabilizerInactive attrs) = runQueueT $ case msg of
    Flip iid _ (isTarget attrs -> True) -> do
      push $ ReplaceInvestigatorAsset iid attrs.id (flipCard $ toCard attrs)
      pure $ FluxStabilizerInactive $ attrs & flippedL .~ True
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      currents <-
        mconcat
          <$> sequence
            [ searchBonded iid Events.aethericCurrentYuggoth
            , searchBonded iid Events.aethericCurrentYoth
            , select
                $ inDiscardOf iid
                <> basic (oneOf [cardIs Events.aethericCurrentYuggoth, cardIs Events.aethericCurrentYoth])
            ]
      when (notNull currents) $ do
        focusCards currents $ chooseTargetM iid currents $ shuffleCardsIntoDeck iid . only
      push $ Flip iid (attrs.ability 1) (toTarget attrs)
      pure a
    _ -> FluxStabilizerInactive <$> liftRunMessage msg attrs
