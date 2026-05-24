package web

// Mini-community bot task bus: cloud-agnostic pub/sub via gocloud.dev with deterministic
// sharding so each automated bot replica can own a slice of communities.

import (
	"context"
	"encoding/json"
	"hash/fnv"
	"os"
	"strconv"
	"strings"

	"gocloud.dev/pubsub"
	_ "gocloud.dev/pubsub/awssnssqs"
	_ "gocloud.dev/pubsub/azuresb"
	_ "gocloud.dev/pubsub/gcppubsub"
)

// EnvQueueTopicURL is the default task topic for [OpenTopicFromEnv].
const EnvQueueTopicURL = "RICE_QUEUE_TOPIC_URL"

// Pub/sub metadata keys for mini-community routing (filtering, observability).
const (
	MetaMiniCommunityID = "rice_minicommunity_id"
	MetaBotTaskKind     = "rice_bot_task_kind"
	MetaRouteShard      = "rice_route_shard"
	MetaTaskID          = "rice_task_id"
)

// Well-known task kinds for community-managing bots (extend as needed).
const (
	BotTaskModerate      = "moderate"
	BotTaskDigest        = "digest"
	BotTaskMemberSync    = "member_sync"
	BotTaskPolicyRefresh = "policy_refresh"
)

// MiniCommunityTask is the envelope for work dispatched to bots. Payload is opaque JSON per Kind.
type MiniCommunityTask struct {
	CommunityID string          `json:"community_id"`
	Kind        string          `json:"kind"`
	Payload     json.RawMessage `json:"payload,omitempty"`
	TaskID      string          `json:"task_id,omitempty"`
	BotActor    string          `json:"bot_actor,omitempty"`
	RouteShard  int             `json:"route_shard,omitempty"`
}

// MiniCommunityRoute selects which communities a bot replica handles (shard of a fleet).
type MiniCommunityRoute struct {
	WorkerIndex int // 0 <= WorkerIndex < Workers
	Workers     int // fleet size; <= 1 means all communities
}

// Owns reports whether this replica should process the community (consistent hashing).
func (r *MiniCommunityRoute) Owns(communityID string) bool {
	if r == nil || r.Workers <= 1 {
		return true
	}
	idx := RouteShardIndex(communityID, r.Workers)
	return idx == r.WorkerIndex
}

// RouteShardIndex is a stable shard in [0, workers) for load spreading across bot replicas.
func RouteShardIndex(communityID string, workers int) int {
	if workers <= 1 {
		return 0
	}
	h := fnv.New32a()
	_, _ = h.Write([]byte(communityID))
	return int(h.Sum32() % uint32(workers))
}

// OpenTopic opens a pubsub topic from URL (driver packages must be imported for scheme registration).
func OpenTopic(ctx context.Context, urlstr string) (*pubsub.Topic, error) {
	return pubsub.OpenTopic(ctx, urlstr)
}

// OpenTopicFromEnv opens the topic at [EnvQueueTopicURL].
func OpenTopicFromEnv(ctx context.Context) (*pubsub.Topic, error) {
	u := strings.TrimSpace(os.Getenv(EnvQueueTopicURL))
	if u == "" {
		return nil, errQueueTopicUnset
	}
	return OpenTopic(ctx, u)
}

// OpenSubscription opens a subscription for bot receive loops.
func OpenSubscription(ctx context.Context, urlstr string) (*pubsub.Subscription, error) {
	return pubsub.OpenSubscription(ctx, urlstr)
}

// PublishMiniCommunityTask sends a task to the shared topic with routing metadata for observability.
// workers is the fleet size used to set [MetaRouteShard]; use 0 to omit shard metadata.
func PublishMiniCommunityTask(ctx context.Context, topic *pubsub.Topic, task MiniCommunityTask, workers int) error {
	if topic == nil {
		return errNilPubSubTopic
	}
	if task.CommunityID == "" || task.Kind == "" {
		return errMiniCommunityTaskInvalid
	}
	if workers > 1 {
		task.RouteShard = RouteShardIndex(task.CommunityID, workers)
	}
	body, err := json.Marshal(task)
	if err != nil {
		return err
	}
	md := map[string]string{
		MetaMiniCommunityID: task.CommunityID,
		MetaBotTaskKind:     task.Kind,
	}
	if task.TaskID != "" {
		md[MetaTaskID] = task.TaskID
	}
	if workers > 1 {
		md[MetaRouteShard] = strconv.Itoa(task.RouteShard)
	}
	return topic.Send(ctx, &pubsub.Message{Body: body, Metadata: md})
}

// DecodeMiniCommunityTask unmarshals the message body and fills RouteShard from metadata when present.
func DecodeMiniCommunityTask(m *pubsub.Message) (MiniCommunityTask, error) {
	var t MiniCommunityTask
	if m == nil || len(m.Body) == 0 {
		return t, errMiniCommunityTaskInvalid
	}
	if err := json.Unmarshal(m.Body, &t); err != nil {
		return t, err
	}
	if m.Metadata != nil {
		if s := m.Metadata[MetaRouteShard]; s != "" {
			if n, err := strconv.Atoi(s); err == nil {
				t.RouteShard = n
			}
		}
	}
	return t, nil
}

// RunMiniCommunityBot receives tasks until ctx is cancelled. Messages that fail decode are acked
// to drop poison pills. Tasks not owned by route are nacked so another replica can receive them.
// Handler errors nack for retry (when the driver supports nack).
func RunMiniCommunityBot(ctx context.Context, sub *pubsub.Subscription, route *MiniCommunityRoute, fn func(context.Context, MiniCommunityTask) error) error {
	if sub == nil {
		return errNilPubSubSub
	}
	if fn == nil {
		return errMiniCommunityHandlerNil
	}
	for {
		m, err := sub.Receive(ctx)
		if err != nil {
			return err
		}
		task, derr := DecodeMiniCommunityTask(m)
		if derr != nil {
			m.Ack()
			continue
		}
		if route != nil && !route.Owns(task.CommunityID) {
			if m.Nackable() {
				m.Nack()
			} else {
				m.Ack()
			}
			continue
		}
		if err := fn(ctx, task); err != nil {
			if m.Nackable() {
				m.Nack()
			}
			continue
		}
		m.Ack()
	}
}
