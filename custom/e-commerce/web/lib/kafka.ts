// Optional Kafka import - app works without it
let Kafka: any;
let Producer: any;
let Consumer: any;
let EachMessagePayload: any;

try {
  const kafkaModule = require("kafkajs");
  Kafka = kafkaModule.Kafka;
  Producer = kafkaModule.Producer;
  Consumer = kafkaModule.Consumer;
  EachMessagePayload = kafkaModule.EachMessagePayload;
} catch (error) {
  // kafkajs not installed - app will work without Kafka
  console.warn("⚠️  kafkajs not available - Kafka features disabled");
}

type KafkaType = typeof Kafka extends new (...args: any[]) => infer T ? T : any;
type ProducerType = typeof Producer extends new (...args: any[]) => infer T ? T : any;
type ConsumerType = typeof Consumer extends new (...args: any[]) => infer T ? T : any;
type EachMessagePayloadType = typeof EachMessagePayload;

const globalForKafka = globalThis as unknown as {
  kafka: KafkaType | undefined;
  producer: ProducerType | undefined;
};

function getKafkaConfig() {
  const broker = process.env.KAFKA_BROKER || "devcontainer-kafka:29092";
  const brokers = broker.split(",").map((b) => b.trim());

  return {
    clientId: process.env.KAFKA_CLIENT_ID || "meowtopia-web",
    brokers,
    retry: {
      initialRetryTime: 100,
      retries: 8,
    },
  };
}

export const kafka =
  globalForKafka.kafka ??
  (Kafka ? new Kafka(getKafkaConfig()) : null);

if (process.env.NODE_ENV !== "production") {
  globalForKafka.kafka = kafka;
}

// Producer for sending messages
let producerInstance: ProducerType | null = null;

export async function getProducer(): Promise<ProducerType | null> {
  if (!kafka || !Producer) {
    return null; // Kafka not available
  }

  if (producerInstance) {
    return producerInstance;
  }

  try {
    producerInstance = kafka.producer();
    await producerInstance.connect();
    console.log("✅ Kafka producer connected");
    return producerInstance;
  } catch (error) {
    console.warn("⚠️  Kafka producer connection error (non-critical):", error instanceof Error ? error.message : error);
    // Don't throw - Kafka is optional for event streaming
    return null;
  }
}

// Consumer for receiving messages
export async function createConsumer(
  groupId: string,
  topics: string[],
  handler: (payload: EachMessagePayloadType) => Promise<void>
): Promise<ConsumerType> {
  try {
    const consumer = kafka.consumer({ groupId });
    await consumer.connect();
    console.log(`✅ Kafka consumer connected (group: ${groupId})`);

    // Subscribe to topics
    for (const topic of topics) {
      await consumer.subscribe({ topic, fromBeginning: false });
    }

    // Start consuming
    await consumer.run({
      eachMessage: async (payload) => {
        try {
          await handler(payload);
        } catch (error) {
          console.error("Error processing Kafka message:", error);
          // Don't throw - continue processing other messages
        }
      },
    });

    return consumer;
  } catch (error) {
    console.error("❌ Kafka consumer connection error:", error);
    throw error;
  }
}

// Helper functions for common Kafka operations
export const kafkaHelpers = {
  // Send analytics event
  async sendAnalyticsEvent(eventType: string, data: any): Promise<void> {
    try {
      const producer = await getProducer();
      if (!producer) {
        // Kafka not available, skip silently
        return;
      }
      await producer.send({
        topic: "meowtopia-analytics",
        messages: [
          {
            key: eventType,
            value: JSON.stringify({
              type: eventType,
              data,
              timestamp: new Date().toISOString(),
            }),
          },
        ],
      });
    } catch (error) {
      // Don't log - Kafka is optional, errors are expected if not available
    }
  },

  // Send dashboard update event
  async sendDashboardUpdate(updateType: string, data: any): Promise<void> {
    try {
      const producer = await getProducer();
      if (!producer) return;
      await producer.send({
        topic: "meowtopia-dashboard",
        messages: [
          {
            key: updateType,
            value: JSON.stringify({
              type: updateType,
              data,
              timestamp: new Date().toISOString(),
            }),
          },
        ],
      });
    } catch (error) {
      // Don't log - Kafka is optional
    }
  },

  // Send order event
  async sendOrderEvent(eventType: string, orderData: any): Promise<void> {
    try {
      const producer = await getProducer();
      if (!producer) return;
      await producer.send({
        topic: "meowtopia-orders",
        messages: [
          {
            key: orderData.id || "unknown",
            value: JSON.stringify({
              type: eventType,
              order: orderData,
              timestamp: new Date().toISOString(),
            }),
          },
        ],
      });
    } catch (error) {
      // Don't log - Kafka is optional
    }
  },

  // Send product event
  async sendProductEvent(eventType: string, productData: any): Promise<void> {
    try {
      const producer = await getProducer();
      if (!producer) return;
      await producer.send({
        topic: "meowtopia-products",
        messages: [
          {
            key: productData.id || "unknown",
            value: JSON.stringify({
              type: eventType,
              product: productData,
              timestamp: new Date().toISOString(),
            }),
          },
        ],
      });
    } catch (error) {
      // Don't log - Kafka is optional
    }
  },
};

// Graceful shutdown
if (typeof window === "undefined") {
  process.on("SIGTERM", async () => {
    if (producerInstance) {
      await producerInstance.disconnect();
    }
  });
}

