{-# OPTIONS_GHC -Wno-orphans #-}

module Arkham.Investigator (
  module Arkham.Investigator,
) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes.Entity.TH
import Arkham.Helpers.Modifiers
import Arkham.Id
import Arkham.Investigator.Investigators
import Arkham.Investigator.Runner
import Arkham.Investigator.Runner qualified as Attrs
import Arkham.Message
import Data.Aeson (Result (..))
import Data.Typeable

instance RunMessage Investigator where
  runMessage msg i@(Investigator a) = do
    modifiers' <- getModifiers (toTarget i)
    let msg' = if Blank `elem` modifiers' then Blanked msg else msg
    Investigator <$> runMessage msg' a

lookupInvestigator :: InvestigatorId -> Investigator
lookupInvestigator iid = case lookup (unInvestigatorId iid) allInvestigators of
  Nothing -> lookupPromoInvestigator iid
  Just c -> toInvestigator c

{- | Handle promo investigators

Some investigators have book versions that are just alternative art
with some replacement cards. Since these investigators are functionally
the same, we proxy the lookup to their non-promo version.

Parallel investigators will need to be handled differently since they
are not functionally the same.
-}
lookupPromoInvestigator :: InvestigatorId -> Investigator
lookupPromoInvestigator "98001" = lookupInvestigator "02003" -- Jenny Barnes
lookupPromoInvestigator "98004" = lookupInvestigator "01001" -- Roland Banks
lookupPromoInvestigator "98007" = lookupInvestigator "08004" -- Norman Withers
lookupPromoInvestigator "98016" = lookupInvestigator "07004" -- Dexter Drake
lookupPromoInvestigator "99001" = lookupInvestigator "05006" -- Marie Lambeau
lookupPromoInvestigator iid = error $ "Unknown investigator: " <> show iid

instance FromJSON Investigator where
  parseJSON = withObject "Investigator" $ \o -> do
    cCode <- o .: "cardCode"
    withInvestigatorCardCode cCode $
      \(SomeInvestigator (_ :: Proxy a)) -> Investigator <$> parseJSON @a (Object o)

withInvestigatorCardCode
  :: CardCode -> (SomeInvestigator -> r) -> r
withInvestigatorCardCode cCode f = case lookup cCode allInvestigators of
  Nothing -> case cCode of
    "04244" -> f (SomeInvestigator (Proxy @BodyOfAYithian))
    "05046" -> f (SomeInvestigator (Proxy @GavriellaMizrah))
    "05047" -> f (SomeInvestigator (Proxy @JeromeDavids))
    "05048" -> f (SomeInvestigator (Proxy @ValentinoRivas))
    "05049" -> f (SomeInvestigator (Proxy @PennyWhite))
    _ -> error ("invalid investigators: " <> show cCode)
  Just (SomeInvestigatorCard (_ :: InvestigatorCard a)) -> f (SomeInvestigator (Proxy @a))

data SomeInvestigator = forall a. IsInvestigator a => SomeInvestigator (Proxy a)

allInvestigators :: Map CardCode SomeInvestigatorCard
allInvestigators =
  mapFromList $
    map
      (toFst someInvestigatorCardCode)
      [ SomeInvestigatorCard rolandBanks
      , SomeInvestigatorCard daisyWalker
      , SomeInvestigatorCard skidsOToole
      , SomeInvestigatorCard agnesBaker
      , SomeInvestigatorCard wendyAdams
      , SomeInvestigatorCard zoeySamaras
      , SomeInvestigatorCard rexMurphy
      , SomeInvestigatorCard jennyBarnes
      , SomeInvestigatorCard jimCulver
      , SomeInvestigatorCard ashcanPete
      , SomeInvestigatorCard markHarrigan
      , SomeInvestigatorCard minhThiPhan
      , SomeInvestigatorCard sefinaRousseau
      , SomeInvestigatorCard akachiOnyele
      , SomeInvestigatorCard williamYorick
      , SomeInvestigatorCard lolaHayes
      , SomeInvestigatorCard leoAnderson
      , SomeInvestigatorCard ursulaDowns
      , SomeInvestigatorCard finnEdwards
      , SomeInvestigatorCard fatherMateo
      , SomeInvestigatorCard calvinWright
      , SomeInvestigatorCard carolynFern
      , SomeInvestigatorCard joeDiamond
      , SomeInvestigatorCard prestonFairmont
      , SomeInvestigatorCard dianaStanley
      , SomeInvestigatorCard ritaYoung
      , SomeInvestigatorCard marieLambeau
      , SomeInvestigatorCard normanWithers
      , SomeInvestigatorCard dexterDrake
      , SomeInvestigatorCard nathanielCho
      , SomeInvestigatorCard harveyWalters
      , SomeInvestigatorCard winifredHabbamock
      , SomeInvestigatorCard stellaClark
      , SomeInvestigatorCard jacquelineFine
      , SomeInvestigatorCard daisyWalkerParallel
      ]

becomeYithian :: Investigator -> Investigator
becomeYithian (Investigator a) =
  Investigator $
    BodyOfAYithian . (`with` YithianMetadata (toJSON a)) $
      (toAttrs a)
        { investigatorHealth = 7
        , investigatorSanity = 7
        , investigatorWillpower = 2
        , investigatorIntellect = 2
        , investigatorCombat = 2
        , investigatorAgility = 2
        , investigatorCardCode = "04244"
        , investigatorClass = Neutral
        , investigatorTraits = setFromList [Monster, Yithian]
        , investigatorIsYithian = True
        , investigatorDiscarding = Nothing
        }

handleInvestigator :: IsInvestigator a => Investigator -> (a -> Investigator) -> Investigator
handleInvestigator o@(Investigator a) f = case cast a of
  Just i -> f i
  Nothing -> o

returnToBody :: Investigator -> Investigator
returnToBody i =
  i
    `handleInvestigator` ( \(BodyOfAYithian (_ `With` meta)) -> case fromJSON (originalBody meta) of
                            Success x -> x
                            _ -> error "Investigator mind is too corrupted to return to their body"
                         )
    `handleInvestigator` ( \(GavriellaMizrah (_ `With` meta)) -> case fromJSON (original meta) of
                            Success x -> x
                            _ -> error "Investigator mind is too corrupted to return to their body"
                         )
    `handleInvestigator` ( \(JeromeDavids (_ `With` meta)) -> case fromJSON (original meta) of
                            Success x -> x
                            _ -> error "Investigator mind is too corrupted to return to their body"
                         )
    `handleInvestigator` ( \(ValentinoRivas (_ `With` meta)) -> case fromJSON (original meta) of
                            Success x -> x
                            _ -> error "Investigator mind is too corrupted to return to their body"
                         )
    `handleInvestigator` ( \(PennyWhite (_ `With` meta)) -> case fromJSON (original meta) of
                            Success x -> x
                            _ -> error "Investigator mind is too corrupted to return to their body"
                         )

becomePrologueInvestigator :: Investigator -> InvestigatorId -> Investigator
becomePrologueInvestigator (Investigator a) = \case
  "05046" ->
    setId $ Investigator $ cbCardBuilder (gavriellaMizrah (PrologueMetadata $ toJSON a)) nullCardId ()
  "05047" -> setId $ Investigator $ cbCardBuilder (jeromeDavids (PrologueMetadata $ toJSON a)) nullCardId ()
  "05048" ->
    setId $ Investigator $ cbCardBuilder (valentinoRivas (PrologueMetadata $ toJSON a)) nullCardId ()
  "05049" -> setId $ Investigator $ cbCardBuilder (pennyWhite (PrologueMetadata $ toJSON a)) nullCardId ()
  _ -> error "Not a prologue investigator"
 where
  setId = overAttrs (\attrs -> attrs {Attrs.investigatorId = toId a})
