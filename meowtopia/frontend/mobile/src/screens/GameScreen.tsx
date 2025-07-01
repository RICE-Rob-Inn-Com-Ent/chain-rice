import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Alert,
  Animated,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

interface Cat {
  id: string;
  name: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  level: number;
  energy: number;
  maxEnergy: number;
  imageUrl?: string;
  attributes: {
    cuteness: number;
    playfulness: number;
    intelligence: number;
  };
}

const GameScreen: React.FC = () => {
  const [selectedCat, setSelectedCat] = useState<Cat | null>(null);
  const [userCats, setUserCats] = useState<Cat[]>([
    {
      id: '1',
      name: 'Whiskers',
      rarity: 'rare',
      level: 5,
      energy: 80,
      maxEnergy: 100,
      attributes: { cuteness: 85, playfulness: 70, intelligence: 60 }
    },
    {
      id: '2',
      name: 'Shadow',
      rarity: 'epic',
      level: 8,
      energy: 60,
      maxEnergy: 100,
      attributes: { cuteness: 75, playfulness: 90, intelligence: 85 }
    }
  ]);
  const [mwtBalance, setMwtBalance] = useState(150);
  const [gameActions, setGameActions] = useState({
    feeding: false,
    playing: false,
    training: false
  });

  const getRarityColor = (rarity: string) => {
    switch (rarity) {
      case 'common': return '#6B7280';
      case 'rare': return '#3B82F6';
      case 'epic': return '#8B5CF6';
      case 'legendary': return '#F59E0B';
      default: return '#6B7280';
    }
  };

  const feedCat = async (cat: Cat) => {
    if (mwtBalance < 10) {
      Alert.alert('Insufficient MWT', 'You need at least 10 MWT to feed your cat');
      return;
    }

    setGameActions(prev => ({ ...prev, feeding: true }));
    
    // Simulate feeding animation
    setTimeout(() => {
      setUserCats(cats => 
        cats.map(c => 
          c.id === cat.id 
            ? { ...c, energy: Math.min(c.maxEnergy, c.energy + 20) }
            : c
        )
      );
      setMwtBalance(prev => prev - 10);
      setGameActions(prev => ({ ...prev, feeding: false }));
      Alert.alert('Fed Successfully!', `${cat.name} is now more energetic!`);
    }, 2000);
  };

  const playCat = async (cat: Cat) => {
    if (cat.energy < 20) {
      Alert.alert('Low Energy', 'Your cat needs more energy to play');
      return;
    }

    setGameActions(prev => ({ ...prev, playing: true }));
    
    setTimeout(() => {
      const reward = Math.floor(Math.random() * 15) + 5;
      setUserCats(cats => 
        cats.map(c => 
          c.id === cat.id 
            ? { ...c, energy: c.energy - 20 }
            : c
        )
      );
      setMwtBalance(prev => prev + reward);
      setGameActions(prev => ({ ...prev, playing: false }));
      Alert.alert('Play Time!', `${cat.name} had fun and you earned ${reward} MWT!`);
    }, 3000);
  };

  const trainCat = async (cat: Cat) => {
    if (cat.energy < 30) {
      Alert.alert('Low Energy', 'Your cat needs more energy to train');
      return;
    }

    setGameActions(prev => ({ ...prev, training: true }));
    
    setTimeout(() => {
      setUserCats(cats => 
        cats.map(c => 
          c.id === cat.id 
            ? { 
                ...c, 
                energy: c.energy - 30,
                attributes: {
                  cuteness: Math.min(100, c.attributes.cuteness + 2),
                  playfulness: Math.min(100, c.attributes.playfulness + 3),
                  intelligence: Math.min(100, c.attributes.intelligence + 5)
                }
              }
            : c
        )
      );
      setGameActions(prev => ({ ...prev, training: false }));
      Alert.alert('Training Complete!', `${cat.name} improved their skills!`);
    }, 4000);
  };

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.balanceContainer}>
          <Ionicons name="diamond" size={20} color="#8B5CF6" />
          <Text style={styles.balanceText}>{mwtBalance} MWT</Text>
        </View>
        <TouchableOpacity style={styles.shopButton}>
          <Ionicons name="storefront" size={20} color="white" />
          <Text style={styles.shopText}>Shop</Text>
        </TouchableOpacity>
      </View>

      {/* My Cats Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>My Cats 🐱</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          {userCats.map((cat) => (
            <TouchableOpacity
              key={cat.id}
              style={[
                styles.catCard,
                { borderColor: getRarityColor(cat.rarity) },
                selectedCat?.id === cat.id && styles.selectedCat
              ]}
              onPress={() => setSelectedCat(cat)}
            >
              <View style={styles.catImageContainer}>
                <Text style={styles.catEmoji}>🐱</Text>
                <View style={[styles.rarityBadge, { backgroundColor: getRarityColor(cat.rarity) }]}>
                  <Text style={styles.rarityText}>{cat.rarity.toUpperCase()}</Text>
                </View>
              </View>
              <Text style={styles.catName}>{cat.name}</Text>
              <Text style={styles.catLevel}>Level {cat.level}</Text>
              <View style={styles.energyBar}>
                <View 
                  style={[
                    styles.energyFill, 
                    { width: `${(cat.energy / cat.maxEnergy) * 100}%` }
                  ]} 
                />
              </View>
              <Text style={styles.energyText}>{cat.energy}/{cat.maxEnergy}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      {/* Cat Actions */}
      {selectedCat && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Actions for {selectedCat.name}</Text>
          <View style={styles.actionsGrid}>
            <TouchableOpacity
              style={[styles.actionButton, gameActions.feeding && styles.actionButtonDisabled]}
              onPress={() => feedCat(selectedCat)}
              disabled={gameActions.feeding}
            >
              <Ionicons name="restaurant" size={24} color="white" />
              <Text style={styles.actionText}>
                {gameActions.feeding ? 'Feeding...' : 'Feed (10 MWT)'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.actionButton, gameActions.playing && styles.actionButtonDisabled]}
              onPress={() => playCat(selectedCat)}
              disabled={gameActions.playing}
            >
              <Ionicons name="game-controller" size={24} color="white" />
              <Text style={styles.actionText}>
                {gameActions.playing ? 'Playing...' : 'Play (20 Energy)'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.actionButton, gameActions.training && styles.actionButtonDisabled]}
              onPress={() => trainCat(selectedCat)}
              disabled={gameActions.training}
            >
              <Ionicons name="barbell" size={24} color="white" />
              <Text style={styles.actionText}>
                {gameActions.training ? 'Training...' : 'Train (30 Energy)'}
              </Text>
            </TouchableOpacity>
          </View>

          {/* Cat Attributes */}
          <View style={styles.attributesContainer}>
            <Text style={styles.attributesTitle}>Attributes</Text>
            <View style={styles.attribute}>
              <Text style={styles.attributeName}>Cuteness</Text>
              <View style={styles.attributeBar}>
                <View 
                  style={[
                    styles.attributeFill, 
                    { width: `${selectedCat.attributes.cuteness}%`, backgroundColor: '#F59E0B' }
                  ]} 
                />
              </View>
              <Text style={styles.attributeValue}>{selectedCat.attributes.cuteness}</Text>
            </View>
            <View style={styles.attribute}>
              <Text style={styles.attributeName}>Playfulness</Text>
              <View style={styles.attributeBar}>
                <View 
                  style={[
                    styles.attributeFill, 
                    { width: `${selectedCat.attributes.playfulness}%`, backgroundColor: '#10B981' }
                  ]} 
                />
              </View>
              <Text style={styles.attributeValue}>{selectedCat.attributes.playfulness}</Text>
            </View>
            <View style={styles.attribute}>
              <Text style={styles.attributeName}>Intelligence</Text>
              <View style={styles.attributeBar}>
                <View 
                  style={[
                    styles.attributeFill, 
                    { width: `${selectedCat.attributes.intelligence}%`, backgroundColor: '#3B82F6' }
                  ]} 
                />
              </View>
              <Text style={styles.attributeValue}>{selectedCat.attributes.intelligence}</Text>
            </View>
          </View>
        </View>
      )}

      {/* Quick Actions */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Quick Actions</Text>
        <View style={styles.quickActions}>
          <TouchableOpacity style={styles.quickActionButton}>
            <Ionicons name="heart" size={20} color="#8B5CF6" />
            <Text style={styles.quickActionText}>Breeding</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.quickActionButton}>
            <Ionicons name="trophy" size={20} color="#8B5CF6" />
            <Text style={styles.quickActionText}>Tournaments</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.quickActionButton}>
            <Ionicons name="storefront" size={20} color="#8B5CF6" />
            <Text style={styles.quickActionText}>Marketplace</Text>
          </TouchableOpacity>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: 'white',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  balanceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  balanceText: {
    marginLeft: 8,
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1f2937',
  },
  shopButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#8B5CF6',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  shopText: {
    color: 'white',
    marginLeft: 4,
    fontWeight: '600',
  },
  section: {
    padding: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 12,
  },
  catCard: {
    width: 140,
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 12,
    marginRight: 12,
    borderWidth: 2,
    borderColor: '#e5e7eb',
  },
  selectedCat: {
    borderWidth: 3,
    borderColor: '#8B5CF6',
  },
  catImageContainer: {
    alignItems: 'center',
    position: 'relative',
    marginBottom: 8,
  },
  catEmoji: {
    fontSize: 48,
  },
  rarityBadge: {
    position: 'absolute',
    top: -5,
    right: -5,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
  },
  rarityText: {
    color: 'white',
    fontSize: 8,
    fontWeight: 'bold',
  },
  catName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1f2937',
    textAlign: 'center',
  },
  catLevel: {
    fontSize: 12,
    color: '#6b7280',
    textAlign: 'center',
    marginBottom: 8,
  },
  energyBar: {
    height: 4,
    backgroundColor: '#e5e7eb',
    borderRadius: 2,
    marginBottom: 4,
  },
  energyFill: {
    height: '100%',
    backgroundColor: '#10B981',
    borderRadius: 2,
  },
  energyText: {
    fontSize: 10,
    color: '#6b7280',
    textAlign: 'center',
  },
  actionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  actionButton: {
    flex: 1,
    minWidth: 100,
    backgroundColor: '#8B5CF6',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  actionButtonDisabled: {
    backgroundColor: '#9ca3af',
  },
  actionText: {
    color: 'white',
    marginTop: 8,
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
  },
  attributesContainer: {
    marginTop: 16,
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 12,
  },
  attributesTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 12,
    color: '#1f2937',
  },
  attribute: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  attributeName: {
    width: 80,
    fontSize: 12,
    color: '#6b7280',
  },
  attributeBar: {
    flex: 1,
    height: 8,
    backgroundColor: '#e5e7eb',
    borderRadius: 4,
    marginHorizontal: 8,
  },
  attributeFill: {
    height: '100%',
    borderRadius: 4,
  },
  attributeValue: {
    width: 30,
    fontSize: 12,
    fontWeight: 'bold',
    color: '#1f2937',
    textAlign: 'right',
  },
  quickActions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  quickActionButton: {
    alignItems: 'center',
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 12,
    minWidth: 80,
  },
  quickActionText: {
    marginTop: 8,
    fontSize: 12,
    color: '#8B5CF6',
    fontWeight: '600',
  },
});

export default GameScreen;