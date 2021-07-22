module Arkham.Types.Agenda.Cards.TheShadowOfTheEclipse
  ( TheShadowOfTheEclipse
  , theShadowOfTheEclipse
  ) where

import Arkham.Prelude

import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Helpers
import Arkham.Types.Agenda.Runner
import Arkham.Types.AssetMatcher
import Arkham.Types.Classes
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Target

newtype TheShadowOfTheEclipse = TheShadowOfTheEclipse AgendaAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theShadowOfTheEclipse :: TheShadowOfTheEclipse
theShadowOfTheEclipse = TheShadowOfTheEclipse
  $ baseAttrs "82003" "The Shadow of the Eclipse" (Agenda 2 A) (Static 3)

instance HasModifiersFor env TheShadowOfTheEclipse

instance HasActions env TheShadowOfTheEclipse where
  getActions i window (TheShadowOfTheEclipse x) = getActions i window x

instance (HasSet AssetId env AssetMatcher, AgendaRunner env) => RunMessage env TheShadowOfTheEclipse where
  runMessage msg a@(TheShadowOfTheEclipse attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 2 B -> do
      maskedCarnevaleGoers <- getSetList @AssetId
        (AssetWithTitle "Masked Carnevale-Goer")
      leadInvestigatorId <- getLeadInvestigatorId
      case maskedCarnevaleGoers of
        [] -> a <$ push (NextAgenda aid "82004")
        xs -> a <$ pushAll
          [ chooseOne
            leadInvestigatorId
            [ Flip (InvestigatorSource leadInvestigatorId) (AssetTarget x)
            | x <- xs
            ]
          , RevertAgenda aid
          ]
    _ -> TheShadowOfTheEclipse <$> runMessage msg attrs