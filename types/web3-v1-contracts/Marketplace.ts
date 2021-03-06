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

export type AdminChanged = ContractEventLog<{
  previousAdmin: string;
  newAdmin: string;
  0: string;
  1: string;
}>;
export type BeaconUpgraded = ContractEventLog<{
  beacon: string;
  0: string;
}>;
export type ChangedOwnerCutPerMillion = ContractEventLog<{
  ownerCutPerMillion: string;
  0: string;
}>;
export type Initialized = ContractEventLog<{
  version: string;
  0: string;
}>;
export type OrderCanceled = ContractEventLog<{
  id: string;
  0: string;
}>;
export type OrderCreated = ContractEventLog<{
  id: string;
  productId: string;
  order: [string, string, string, string, string, string, string];
  0: string;
  1: string;
  2: [string, string, string, string, string, string, string];
}>;
export type OrderSellout = ContractEventLog<{
  id: string;
  amount: string;
  tknRate: string;
  isSellout: boolean;
  0: string;
  1: string;
  2: string;
  3: boolean;
}>;
export type RoleAdminChanged = ContractEventLog<{
  role: string;
  previousAdminRole: string;
  newAdminRole: string;
  0: string;
  1: string;
  2: string;
}>;
export type RoleGranted = ContractEventLog<{
  role: string;
  account: string;
  sender: string;
  0: string;
  1: string;
  2: string;
}>;
export type RoleRevoked = ContractEventLog<{
  role: string;
  account: string;
  sender: string;
  0: string;
  1: string;
  2: string;
}>;
export type Upgraded = ContractEventLog<{
  implementation: string;
  0: string;
}>;

export interface Marketplace extends BaseContract {
  constructor(
    jsonInterface: any[],
    address?: string,
    options?: ContractOptions
  ): Marketplace;
  clone(): Marketplace;
  methods: {
    DEFAULT_ADMIN_ROLE(): NonPayableTransactionObject<string>;

    DOMAIN_SEPARATOR(): NonPayableTransactionObject<string>;

    GM_ROLE(): NonPayableTransactionObject<string>;

    MINTER_ROLE(): NonPayableTransactionObject<string>;

    UPGRADER_ROLE(): NonPayableTransactionObject<string>;

    /**
     * Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role's admin, use {_setRoleAdmin}.
     */
    getRoleAdmin(role: string | number[]): NonPayableTransactionObject<string>;

    /**
     * Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``'s admin role.
     */
    grantRole(
      role: string | number[],
      account: string
    ): NonPayableTransactionObject<void>;

    /**
     * Returns `true` if `account` has been granted `role`.
     */
    hasRole(
      role: string | number[],
      account: string
    ): NonPayableTransactionObject<boolean>;

    isTrustedForwarder(forwarder: string): NonPayableTransactionObject<boolean>;

    orderById(arg0: number | string | BN): NonPayableTransactionObject<{
      id: string;
      seller: string;
      tokenId: string;
      amount: string;
      nft: string;
      priceInWeiForUnit: string;
      acceptedToken: string;
      0: string;
      1: string;
      2: string;
      3: string;
      4: string;
      5: string;
      6: string;
    }>;

    ownerCutPerMillion(): NonPayableTransactionObject<string>;

    productManager(): NonPayableTransactionObject<string>;

    /**
     * Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the implementation. It is used to validate that the this implementation remains valid after an upgrade. IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    proxiableUUID(): NonPayableTransactionObject<string>;

    /**
     * Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function's purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been revoked `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`.
     */
    renounceRole(
      role: string | number[],
      account: string
    ): NonPayableTransactionObject<void>;

    /**
     * Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``'s admin role.
     */
    revokeRole(
      role: string | number[],
      account: string
    ): NonPayableTransactionObject<void>;

    /**
     * Upgrade the implementation of the proxy to `newImplementation`. Calls {_authorizeUpgrade}. Emits an {Upgraded} event.
     */
    upgradeTo(newImplementation: string): NonPayableTransactionObject<void>;

    /**
     * Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call encoded in `data`. Calls {_authorizeUpgrade}. Emits an {Upgraded} event.
     */
    upgradeToAndCall(
      newImplementation: string,
      data: string | number[]
    ): PayableTransactionObject<void>;

    initialize(mpc: string, _pm: string): NonPayableTransactionObject<void>;

    setOwnerCutPerMillion(
      _ownerCutPerMillion: number | string | BN
    ): NonPayableTransactionObject<void>;

    test(): NonPayableTransactionObject<void>;

    executeOrder(
      orderId: number | string | BN,
      tknRate: number | string | BN,
      buyer: string,
      amount: number | string | BN,
      priceInWeiForUnit: number | string | BN
    ): NonPayableTransactionObject<void>;

    /**
     * See {IERC165-supportsInterface}.
     */
    supportsInterface(
      interfaceId: string | number[]
    ): NonPayableTransactionObject<boolean>;

    onERC1155BatchReceived(
      arg0: string,
      _from: string,
      _ids: (number | string | BN)[],
      _amounts: (number | string | BN)[],
      _data: string | number[]
    ): NonPayableTransactionObject<string>;

    /**
     * Will pass to onERC115Batch5Received
     */
    onERC1155Received(
      _operator: string,
      _from: string,
      _id: number | string | BN,
      _amount: number | string | BN,
      _data: string | number[]
    ): NonPayableTransactionObject<string>;
  };
  events: {
    AdminChanged(cb?: Callback<AdminChanged>): EventEmitter;
    AdminChanged(
      options?: EventOptions,
      cb?: Callback<AdminChanged>
    ): EventEmitter;

    BeaconUpgraded(cb?: Callback<BeaconUpgraded>): EventEmitter;
    BeaconUpgraded(
      options?: EventOptions,
      cb?: Callback<BeaconUpgraded>
    ): EventEmitter;

    ChangedOwnerCutPerMillion(
      cb?: Callback<ChangedOwnerCutPerMillion>
    ): EventEmitter;
    ChangedOwnerCutPerMillion(
      options?: EventOptions,
      cb?: Callback<ChangedOwnerCutPerMillion>
    ): EventEmitter;

    Initialized(cb?: Callback<Initialized>): EventEmitter;
    Initialized(
      options?: EventOptions,
      cb?: Callback<Initialized>
    ): EventEmitter;

    OrderCanceled(cb?: Callback<OrderCanceled>): EventEmitter;
    OrderCanceled(
      options?: EventOptions,
      cb?: Callback<OrderCanceled>
    ): EventEmitter;

    OrderCreated(cb?: Callback<OrderCreated>): EventEmitter;
    OrderCreated(
      options?: EventOptions,
      cb?: Callback<OrderCreated>
    ): EventEmitter;

    OrderSellout(cb?: Callback<OrderSellout>): EventEmitter;
    OrderSellout(
      options?: EventOptions,
      cb?: Callback<OrderSellout>
    ): EventEmitter;

    RoleAdminChanged(cb?: Callback<RoleAdminChanged>): EventEmitter;
    RoleAdminChanged(
      options?: EventOptions,
      cb?: Callback<RoleAdminChanged>
    ): EventEmitter;

    RoleGranted(cb?: Callback<RoleGranted>): EventEmitter;
    RoleGranted(
      options?: EventOptions,
      cb?: Callback<RoleGranted>
    ): EventEmitter;

    RoleRevoked(cb?: Callback<RoleRevoked>): EventEmitter;
    RoleRevoked(
      options?: EventOptions,
      cb?: Callback<RoleRevoked>
    ): EventEmitter;

    Upgraded(cb?: Callback<Upgraded>): EventEmitter;
    Upgraded(options?: EventOptions, cb?: Callback<Upgraded>): EventEmitter;

    allEvents(options?: EventOptions, cb?: Callback<EventLog>): EventEmitter;
  };

  once(event: "AdminChanged", cb: Callback<AdminChanged>): void;
  once(
    event: "AdminChanged",
    options: EventOptions,
    cb: Callback<AdminChanged>
  ): void;

  once(event: "BeaconUpgraded", cb: Callback<BeaconUpgraded>): void;
  once(
    event: "BeaconUpgraded",
    options: EventOptions,
    cb: Callback<BeaconUpgraded>
  ): void;

  once(
    event: "ChangedOwnerCutPerMillion",
    cb: Callback<ChangedOwnerCutPerMillion>
  ): void;
  once(
    event: "ChangedOwnerCutPerMillion",
    options: EventOptions,
    cb: Callback<ChangedOwnerCutPerMillion>
  ): void;

  once(event: "Initialized", cb: Callback<Initialized>): void;
  once(
    event: "Initialized",
    options: EventOptions,
    cb: Callback<Initialized>
  ): void;

  once(event: "OrderCanceled", cb: Callback<OrderCanceled>): void;
  once(
    event: "OrderCanceled",
    options: EventOptions,
    cb: Callback<OrderCanceled>
  ): void;

  once(event: "OrderCreated", cb: Callback<OrderCreated>): void;
  once(
    event: "OrderCreated",
    options: EventOptions,
    cb: Callback<OrderCreated>
  ): void;

  once(event: "OrderSellout", cb: Callback<OrderSellout>): void;
  once(
    event: "OrderSellout",
    options: EventOptions,
    cb: Callback<OrderSellout>
  ): void;

  once(event: "RoleAdminChanged", cb: Callback<RoleAdminChanged>): void;
  once(
    event: "RoleAdminChanged",
    options: EventOptions,
    cb: Callback<RoleAdminChanged>
  ): void;

  once(event: "RoleGranted", cb: Callback<RoleGranted>): void;
  once(
    event: "RoleGranted",
    options: EventOptions,
    cb: Callback<RoleGranted>
  ): void;

  once(event: "RoleRevoked", cb: Callback<RoleRevoked>): void;
  once(
    event: "RoleRevoked",
    options: EventOptions,
    cb: Callback<RoleRevoked>
  ): void;

  once(event: "Upgraded", cb: Callback<Upgraded>): void;
  once(event: "Upgraded", options: EventOptions, cb: Callback<Upgraded>): void;
}
