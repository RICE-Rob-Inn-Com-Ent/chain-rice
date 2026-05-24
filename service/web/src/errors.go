package web

import "errors"

var (
	errNilBucket                = errors.New("web: nil blob bucket")
	errNilKeeper                = errors.New("web: nil secrets keeper")
	errNilPubSubTopic           = errors.New("web: nil pubsub topic")
	errNilPubSubSub             = errors.New("web: nil pubsub subscription")
	errStorageURLUnset          = errors.New("web: RICE_STORAGE_URL unset")
	errQueueTopicUnset          = errors.New("web: RICE_QUEUE_TOPIC_URL unset")
	errMiniCommunityTaskInvalid = errors.New("web: invalid mini-community task")
	errMiniCommunityHandlerNil  = errors.New("web: nil mini-community handler")

	// Scout pipeline errors (Truth Filter, semantic tier, SAGE verification).
	ErrScoutLowTrust   = errors.New("web.scout: node trust below threshold")
	ErrScoutLowQuality = errors.New("web.scout: semantic quality below minimum")
	ErrScoutSageReject = errors.New("web.scout: SAGE logic verification rejected")
	ErrScoutNilBucket  = errors.New("web.scout: nil blob bucket")

	// Anti-Manifesto (Connect interceptor) policy outcomes.
	ErrAntiManifestoIsolate = errors.New("web: anti-manifesto isolate")
	ErrAntiManifestoEject   = errors.New("web: anti-manifesto eject")

	// Dead Man's Switch: author presence stale beyond threshold (see middleware).
	ErrDeadMansSwitchTripped = errors.New("web: dead man's switch tripped — self-destruct armed")
)

// RPCStatus is a minimal google.rpc.Status-shaped JSON body for HTTP APIs.
type RPCStatus struct {
	Code    string `json:"code,omitempty"`
	Message string `json:"message"`
	Details []any  `json:"details,omitempty"`
}
