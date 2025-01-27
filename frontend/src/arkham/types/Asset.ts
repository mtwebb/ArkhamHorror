import { JsonDecoder } from 'ts.data.json';
import { ChaosToken, chaosTokenDecoder } from '@/arkham/types/ChaosToken';
import {
  Card,
  cardDecoder,
} from '@/arkham/types/Card';
import { ArkhamKey, arkhamKeyDecoder } from '@/arkham/types/Key';
import { Tokens, tokensDecoder } from '@/arkham/types/Token';

export interface Uses {
  amount: number; // eslint-disable-line
}

export const usesDecoder = JsonDecoder.object<Uses>({
  amount: JsonDecoder.number,
}, 'Uses');

export interface Asset {
  id: string;
  cardCode: string;
  cardId: string;
  owner: string | null;
  health: number | null;
  sanity: number | null;
  tokens: Tokens;
  uses: Uses | null;
  exhausted: boolean;
  events: string[];
  assets: string[];
  cardsUnderneath: Card[];
  sealedChaosTokens: ChaosToken[];
  keys: ArkhamKey[];
}

export const assetDecoder = JsonDecoder.object<Asset>({
  id: JsonDecoder.string,
  cardCode: JsonDecoder.string,
  cardId: JsonDecoder.string,
  owner: JsonDecoder.nullable(JsonDecoder.string),
  health: JsonDecoder.nullable(JsonDecoder.number),
  tokens: tokensDecoder,
  sanity: JsonDecoder.nullable(JsonDecoder.number),
  uses: JsonDecoder.nullable(usesDecoder),
  exhausted: JsonDecoder.boolean,
  events: JsonDecoder.array<string>(JsonDecoder.string, 'EventId[]'),
  assets: JsonDecoder.array<string>(JsonDecoder.string, 'AssetId[]'),
  cardsUnderneath: JsonDecoder.array<Card>(cardDecoder, 'CardUnderneath'),
  sealedChaosTokens: JsonDecoder.array<ChaosToken>(chaosTokenDecoder, 'ChaosToken[]'),
    keys: JsonDecoder.array<ArkhamKey>(arkhamKeyDecoder, 'Key[]'),
}, 'Asset');
