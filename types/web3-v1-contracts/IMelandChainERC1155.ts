/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import type BN from "bn.js";
import type { ContractOptions } from "web3-eth-contract";
import type { EventLog } from "web3-core";
import type { EventEmitter } from "events";
import type {
  Callback,
  PayableTransactionObject,
  NonPayableTransactionObject,
  BlockType,
  ContractEventLog,
  BaseContract,
} from "./types";

export interface EventOptions {
  filter?: object;
  fromBlock?: BlockType;
  topics?: string[];
}

export type RefundSwapin = ContractEventLog<{
  signKeccak256: string;
  0: string;
}>;
export type SwapinWithTokenId = ContractEventLog<{
  signKeccak256: string;
  to: string;
  tokenId: string;
  value: string;
  0: string;
  1: string;
  2: string;
  3: string;
}>;
export type SwapoutWithTokenId = ContractEventLog<{
  to: string;
  tokenId: string;
  value: string;
  0: string;
  1: string;
  2: string;
}>;

export interface IMelandChainERC1155 extends BaseContract {
  constructor(
    jsonInterface: any[],
    address?: string,
    options?: ContractOptions
  ): IMelandChainERC1155;
  clone(): IMelandChainERC1155;
  methods: {
    /**
     * Returns true if this contract implements the interface defined by `interfaceId`. See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section] to learn more about how these ids are created. This function call must use less than 30 000 gas.
     */
    supportsInterface(
      interfaceId: string | number[]
    ): NonPayableTransactionObject<boolean>;

    callSwapoutWithTokenId(
      to: string,
      tokenId: number | string | BN,
      value: number | string | BN
    ): NonPayableTransactionObject<void>;

    callSwapinWithTokenId(
      signature: string | number[],
      swapinparams: [
        string,
        string,
        number | string | BN,
        number | string | BN,
        number | string | BN,
        number | string | BN,
        string | number[]
      ]
    ): NonPayableTransactionObject<void>;
  };
  events: {
    RefundSwapin(cb?: Callback<RefundSwapin>): EventEmitter;
    RefundSwapin(
      options?: EventOptions,
      cb?: Callback<RefundSwapin>
    ): EventEmitter;

    SwapinWithTokenId(cb?: Callback<SwapinWithTokenId>): EventEmitter;
    SwapinWithTokenId(
      options?: EventOptions,
      cb?: Callback<SwapinWithTokenId>
    ): EventEmitter;

    SwapoutWithTokenId(cb?: Callback<SwapoutWithTokenId>): EventEmitter;
    SwapoutWithTokenId(
      options?: EventOptions,
      cb?: Callback<SwapoutWithTokenId>
    ): EventEmitter;

    allEvents(options?: EventOptions, cb?: Callback<EventLog>): EventEmitter;
  };

  once(event: "RefundSwapin", cb: Callback<RefundSwapin>): void;
  once(
    event: "RefundSwapin",
    options: EventOptions,
    cb: Callback<RefundSwapin>
  ): void;

  once(event: "SwapinWithTokenId", cb: Callback<SwapinWithTokenId>): void;
  once(
    event: "SwapinWithTokenId",
    options: EventOptions,
    cb: Callback<SwapinWithTokenId>
  ): void;

  once(event: "SwapoutWithTokenId", cb: Callback<SwapoutWithTokenId>): void;
  once(
    event: "SwapoutWithTokenId",
    options: EventOptions,
    cb: Callback<SwapoutWithTokenId>
  ): void;
}