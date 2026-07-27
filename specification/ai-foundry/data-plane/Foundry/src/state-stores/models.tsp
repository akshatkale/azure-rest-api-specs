// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import "../common/service.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

namespace Azure.AI.Projects;

const StateStoreRequiredPreviews = #{
  required_previews: #[FoundryFeaturesOptInKeys.state_stores_v1_preview],
};

// ---------------------------------------------------------------------------
// Object-type discriminators (real wire values, preserved from the prose spec).
// ---------------------------------------------------------------------------

/** The `object` discriminator for a state-store resource. */
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
union StateStoreObjectType {
  stateStore: "state_store",
}

/** The `object` discriminator for a state-store item resource. */
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
union StateStoreItemObjectType {
  stateStoreItem: "state_store.item",
}

// ---------------------------------------------------------------------------
// 4.1 State Store resource
// ---------------------------------------------------------------------------

/** A first-class, explicitly-created durable key-value store (spec §2, §4.1). */
@doc("A first-class, explicitly-created durable key-value store.")
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
model StateStore {
  @doc("The object type, which is always 'state_store'.")
  object: StateStoreObjectType.stateStore;

  @doc("Server-assigned, read-only identifier. Not used for addressing (the `name` is).")
  id: string;

  @doc("Caller-chosen logical name. Unique within [project_id, agent_guid]. May contain `/` as a hierarchy separator. Immutable.")
  @minLength(1)
  @maxLength(128)
  @visibility(Lifecycle.Create, Lifecycle.Read)
  name: string;

  @doc("Whether item operations are partitioned per resolved user. Omitted at create -> `false`. Immutable.")
  @visibility(Lifecycle.Create, Lifecycle.Read)
  user_isolation: boolean = false;

  @doc("Store-wide default TTL (seconds) inherited by every item, write-sliding per item. `-1` = never expire. Immutable.")
  @minValue(-1)
  @maxValue(2147483647)
  @visibility(Lifecycle.Create, Lifecycle.Read)
  item_ttl_seconds: int32 = 2592000;

  @doc("Optional free-form description. Mutable via `updateStateStore`.")
  @maxLength(1024)
  description?: string;

  @doc("Optional string-to-string labels. Mutable (replaced wholesale) via `updateStateStore`.")
  tags?: Record<string>;

  @doc("The Unix timestamp (seconds) when the store was created.")
  created_at: FoundryTimestamp;

  @doc("The Unix timestamp (seconds) when the store metadata was last updated.")
  updated_at: FoundryTimestamp;
}

/** Response for `deleteStateStore` (spec §4.1.5). Idempotent. */
@doc("Response for deleting a state store.")
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
model DeletedStateStore {
  @doc("The object type, which is always 'state_store'.")
  object: StateStoreObjectType.stateStore;

  @doc("Present when the store existed; absent when the delete was a no-op (already gone).")
  id?: string;

  @doc("The name of the state store.")
  name: string;

  @doc("Whether the state store was deleted. Always `true`.")
  deleted: boolean;
}

// ---------------------------------------------------------------------------
// 4.2 Item resource
// ---------------------------------------------------------------------------

/** A single `key -> value` record within a state store (spec §2, §4.2). */
@doc("A single key -> value record within a state store.")
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
model StateStoreItem {
  @doc("The object type, which is always 'state_store.item'.")
  object: StateStoreItemObjectType.stateStoreItem;

  @doc("Server-assigned, read-only identifier. Not used for addressing (the `key` is).")
  id: string;

  @doc("Logical key, unique within the store. May contain `/`.")
  @minLength(1)
  @maxLength(128)
  key: string;

  @doc("Opaque JSON object; stored and returned verbatim. <= 1 MB serialized inline.")
  value: Record<unknown>;

  @doc("Optional labels used to filter `listKeys`. Replaced wholesale on write.")
  tags?: Record<string>;

  @doc("Optimistic-concurrency token for this item; also echoed in the `ETag` response header.")
  etag: string;

  @doc("The Unix timestamp (seconds) when the item was created.")
  created_at: FoundryTimestamp;

  @doc("The Unix timestamp (seconds) when the item was last updated.")
  updated_at: FoundryTimestamp;
}

/**
 * Response for `createItem` / `putItem` (spec §4.2.1/§4.2.2) — server metadata
 * only, no `value` echoed back.
 */
@doc("Server metadata for a written state-store item (no value echoed back).")
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
model StateStoreItemRef {
  @doc("The object type, which is always 'state_store.item'.")
  object: StateStoreItemObjectType.stateStoreItem;

  @doc("Server-assigned, read-only identifier.")
  id: string;

  @doc("Logical key of the item.")
  key: string;

  @doc("Optimistic-concurrency token; also echoed in the `ETag` response header.")
  etag: string;

  @doc("The Unix timestamp (seconds) when the item was created.")
  created_at: FoundryTimestamp;

  @doc("The Unix timestamp (seconds) when the item was last updated.")
  updated_at: FoundryTimestamp;
}

/** Response for `deleteItem` (spec §4.2.4). Idempotent. */
@doc("Response for deleting a state-store item.")
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
model DeletedStateStoreItem {
  @doc("The object type, which is always 'state_store.item'.")
  object: StateStoreItemObjectType.stateStoreItem;

  @doc("Present when the item existed; absent when the delete was a no-op (already gone).")
  id?: string;

  @doc("Logical key of the item.")
  key: string;

  @doc("Whether the item was deleted. Always `true`.")
  deleted: boolean;
}

/** A keys-only projection entry returned by `listKeys` (spec §4.2.5) — never includes `value`. */
@doc("A keys-only projection of a state-store item (never includes the value).")
@extension("x-ms-foundry-meta", StateStoreRequiredPreviews)
model StateStoreItemKey {
  @doc("The object type, which is always 'state_store.item'.")
  object: StateStoreItemObjectType.stateStoreItem;

  @doc("Server-assigned, read-only identifier.")
  id: string;

  @doc("Logical key of the item.")
  key: string;

  @doc("Optional labels associated with the item.")
  tags?: Record<string>;

  @doc("Optimistic-concurrency token for this item.")
  etag: string;

  @doc("The Unix timestamp (seconds) when the item was created.")
  created_at: FoundryTimestamp;

  @doc("The Unix timestamp (seconds) when the item was last updated.")
  updated_at: FoundryTimestamp;
}

// ---------------------------------------------------------------------------
// Request envelopes (path + query + header + body), one alias per operation.
// Non-@path/@query/@header fields form the JSON request body.
// ---------------------------------------------------------------------------

alias CreateStateStoreRequest = {
  @doc("Required. Unique within [project_id, agent_guid].")
  @minLength(1)
  @maxLength(128)
  name: string;

  @doc("Optional. Omitted -> `false` (agent-level, shared). Fixed at create.")
  user_isolation?: boolean = false;

  @doc("Optional. Default 30 days (2592000). `-1` = never expire. Fixed at create.")
  @minValue(-1)
  @maxValue(2147483647)
  item_ttl_seconds?: int32 = 2592000;

  @doc("Optional free-form description.")
  @maxLength(1024)
  description?: string;

  @doc("Optional string-to-string labels.")
  tags?: Record<string>;
};

alias ListStateStoresRequest = {
  ...CommonPageQueryParameters;
};

alias GetStateStoreRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;
};

alias UpdateStateStoreRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;

  @doc("Optional free-form description. A present value replaces the stored one.")
  @maxLength(1024)
  description?: string;

  @doc("Optional string-to-string labels. Replaced wholesale (not merged) when present.")
  tags?: Record<string>;
};

alias DeleteStateStoreRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;
};

alias CreateItemRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;

  @doc("Logical key, unique within the store. May contain `/`.")
  @minLength(1)
  @maxLength(128)
  key: string;

  @doc("Opaque JSON object; stored and returned verbatim.")
  value: Record<unknown>;

  @doc("Optional labels used to filter `listKeys`.")
  tags?: Record<string>;
};

alias ListItemKeysRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;

  @doc("Optional tag-equality filters. SDKs serialize each entry as a `tags.<name>=<value>` query parameter and combine entries with AND semantics.")
  @query
  @extension("x-ms-foundry-query-prefix", "tags.")
  tags?: Record<string>;

  ...CommonPageQueryParameters;
};

alias PutItemRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;

  @doc("The logical item key. SDKs accept the unencoded key and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  key: string;

  @doc("`\"<etag>\"` for a conditional write, or `\"*\"` to require the item already exists. Omit for unconditional last-write-wins.")
  @header("If-Match")
  if_match?: string;

  @doc("Opaque JSON object; stored and returned verbatim.")
  value: Record<unknown>;

  @doc("Optional labels used to filter `listKeys`.")
  tags?: Record<string>;
};

alias GetItemRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;

  @doc("The logical item key. SDKs accept the unencoded key and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  key: string;
};

alias DeleteItemRequest = {
  @doc("The logical name of the state store. SDKs accept the unencoded name and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  name: string;

  @doc("The logical item key. SDKs accept the unencoded key and apply unpadded base64url encoding to the path segment.")
  @path
  @extension("x-ms-foundry-path-encoding", "base64url")
  @minLength(1)
  @maxLength(128)
  key: string;

  @doc("`\"<etag>\"` for a conditional delete. Omit for unconditional delete.")
  @header("If-Match")
  if_match?: string;
};

/** Response header returned with successful item reads and writes. */
alias StateStoreItemEtagResponseHeader = {
  @doc("The optimistic-concurrency token for the item. This value is identical to the `etag` property in the response body.")
  @header("ETag")
  etag_header: string;
};

/** Response for creating an item. */
alias CreateStateStoreItemResponse = ResourceCreatedResponse<StateStoreItemRef> &
  StateStoreItemEtagResponseHeader;

/** Response for replacing an existing item or creating a missing item. */
alias PutStateStoreItemResponse =
  | (Response<200> & StateStoreItemRef & StateStoreItemEtagResponseHeader)
  | (ResourceCreatedResponse<StateStoreItemRef> &
      StateStoreItemEtagResponseHeader);

/** Response for retrieving an item. */
alias GetStateStoreItemResponse = Response<200> &
  StateStoreItem &
  StateStoreItemEtagResponseHeader;

/** Error envelope for conditional item operations. The ETag header is returned on a 412 response when a current item exists. */
@error
model StateStoreConditionalErrorResponse {
  error: ApiError;

  @doc("The current optimistic-concurrency token when the request fails with 412 Precondition Failed and the item exists.")
  @header("ETag")
  etag_header?: string;
}
