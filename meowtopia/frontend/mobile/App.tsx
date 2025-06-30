import React, { useState, useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, View, Alert } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Screens
import HomeScreen from './src/screens/HomeScreen';
import CatsScreen from './src/screens/CatsScreen';
import GameScreen from './src/screens/GameScreen';
import WalletScreen from './src/screens/WalletScreen';
import ProfileScreen from './src/screens/ProfileScreen';
import LoginScreen from './src/screens/LoginScreen';
import RegisterScreen from './src/screens/RegisterScreen';
import CatDetailScreen from './src/screens/CatDetailScreen';
import BreedingScreen from './src/screens/BreedingScreen';
import TournamentScreen from './src/screens/TournamentScreen';

// Context
import { AuthProvider, useAuth } from './src/context/AuthContext';
import { GameProvider } from './src/context/GameContext';
import { WalletProvider } from './src/context/WalletContext';

// Types
export type RootStackParamList = {
  MainTabs: undefined;
  Login: undefined;
  Register: undefined;
  CatDetail: { catId: string };
  Breeding: undefined;
  Tournament: { tournamentId?: string };
};

export type MainTabParamList = {
  Home: undefined;
  Cats: undefined;
  Game: undefined;
  Wallet: undefined;
  Profile: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap;

          if (route.name === 'Home') {
            iconName = focused ? 'home' : 'home-outline';
          } else if (route.name === 'Cats') {
            iconName = focused ? 'paw' : 'paw-outline';
          } else if (route.name === 'Game') {
            iconName = focused ? 'game-controller' : 'game-controller-outline';
          } else if (route.name === 'Wallet') {
            iconName = focused ? 'wallet' : 'wallet-outline';
          } else if (route.name === 'Profile') {
            iconName = focused ? 'person' : 'person-outline';
          } else {
            iconName = 'help-outline';
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#8B5CF6',
        tabBarInactiveTintColor: 'gray',
        tabBarStyle: {
          backgroundColor: '#ffffff',
          borderTopWidth: 1,
          borderTopColor: '#e5e7eb',
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
        headerStyle: {
          backgroundColor: '#8B5CF6',
        },
        headerTintColor: '#ffffff',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      })}
    >
      <Tab.Screen 
        name="Home" 
        component={HomeScreen} 
        options={{ title: 'Meowtopia' }}
      />
      <Tab.Screen 
        name="Cats" 
        component={CatsScreen} 
        options={{ title: 'My Cats' }}
      />
      <Tab.Screen 
        name="Game" 
        component={GameScreen} 
        options={{ title: 'Games' }}
      />
      <Tab.Screen 
        name="Wallet" 
        component={WalletScreen} 
        options={{ title: 'Wallet' }}
      />
      <Tab.Screen 
        name="Profile" 
        component={ProfileScreen} 
        options={{ title: 'Profile' }}
      />
    </Tab.Navigator>
  );
}

function AppNavigator() {
  const { user, loading } = useAuth();

  if (loading) {
    return <View style={styles.loading} />;
  }

  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: {
            backgroundColor: '#8B5CF6',
          },
          headerTintColor: '#ffffff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        {user ? (
          // Authenticated stack
          <>
            <Stack.Screen 
              name="MainTabs" 
              component={MainTabs} 
              options={{ headerShown: false }}
            />
            <Stack.Screen 
              name="CatDetail" 
              component={CatDetailScreen} 
              options={{ title: 'Cat Details' }}
            />
            <Stack.Screen 
              name="Breeding" 
              component={BreedingScreen} 
              options={{ title: 'Cat Breeding' }}
            />
            <Stack.Screen 
              name="Tournament" 
              component={TournamentScreen} 
              options={{ title: 'Tournament' }}
            />
          </>
        ) : (
          // Authentication stack
          <>
            <Stack.Screen 
              name="Login" 
              component={LoginScreen} 
              options={{ title: 'Welcome to Meowtopia' }}
            />
            <Stack.Screen 
              name="Register" 
              component={RegisterScreen} 
              options={{ title: 'Join Meowtopia' }}
            />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <WalletProvider>
        <GameProvider>
          <View style={styles.container}>
            <AppNavigator />
            <StatusBar style="light" />
          </View>
        </GameProvider>
      </WalletProvider>
    </AuthProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  loading: {
    flex: 1,
    backgroundColor: '#8B5CF6',
  },
});