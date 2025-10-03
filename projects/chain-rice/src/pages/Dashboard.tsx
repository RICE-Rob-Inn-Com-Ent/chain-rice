import React from 'react'
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  LinearProgress,
  IconButton,
  Tooltip,
} from '@mui/material'
import {
  Refresh as RefreshIcon,
  TrendingUp as TrendingUpIcon,
  AccountBalance as BalanceIcon,
  Send as SendIcon,
  Code as CodeIcon,
  Explore as ExploreIcon,
} from '@mui/icons-material'
import { useQuery } from '@tanstack/react-query'
import toast from 'react-hot-toast'

// Mock data for demonstration
const mockData = {
  blockchain: {
    status: 'healthy',
    blockHeight: 12345,
    chainId: 'chainrice-1',
    nodeInfo: 'ChainRice Node v1.0.0',
  },
  tokens: {
    crice: {
      symbol: 'CRICE',
      balance: '1000.00',
      price: '$0.50',
      change: '+5.2%',
    },
    mwt: {
      symbol: 'MWT',
      balance: '500.00',
      price: '$0.25',
      change: '+2.1%',
    },
  },
  services: [
    { name: 'Blockchain RPC', status: 'online', port: 26657 },
    { name: 'REST API', status: 'online', port: 1317 },
    { name: 'Bot Core API', status: 'online', port: 8000 },
    { name: 'FastAPI Connection', status: 'online', port: 8001 },
    { name: 'PostgreSQL', status: 'online', port: 5432 },
    { name: 'Redis', status: 'online', port: 6379 },
    { name: 'Kafka', status: 'online', port: 9092 },
  ],
}

const Dashboard: React.FC = () => {
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['dashboard'],
    queryFn: async () => {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      return mockData
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  })

  const handleRefresh = () => {
    refetch()
    toast.success('Dashboard refreshed!')
  }

  if (isLoading) {
    return (
      <Box sx={{ width: '100%', mt: 2 }}>
        <LinearProgress />
        <Typography variant="h6" sx={{ mt: 2, textAlign: 'center' }}>
          Loading dashboard...
        </Typography>
      </Box>
    )
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" className="gradient-text">
          ChainRice Dashboard
        </Typography>
        <Tooltip title="Refresh Dashboard">
          <IconButton onClick={handleRefresh} color="primary">
            <RefreshIcon />
          </IconButton>
        </Tooltip>
      </Box>

      <Grid container spacing={3}>
        {/* Blockchain Status */}
        <Grid item xs={12} md={6}>
          <Card className="glass fade-in">
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <TrendingUpIcon sx={{ mr: 1, color: '#667eea' }} />
                <Typography variant="h6">Blockchain Status</Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Chip 
                  label={data?.blockchain.status} 
                  color="success" 
                  size="small"
                  sx={{ mb: 1 }}
                />
                <Typography variant="body2" color="text.secondary">
                  Chain ID: {data?.blockchain.chainId}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Block Height: {data?.blockchain.blockHeight?.toLocaleString()}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Node: {data?.blockchain.nodeInfo}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Token Balances */}
        <Grid item xs={12} md={6}>
          <Card className="glass fade-in">
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <BalanceIcon sx={{ mr: 1, color: '#667eea' }} />
                <Typography variant="h6">Token Balances</Typography>
              </Box>
              {Object.entries(data?.tokens || {}).map(([key, token]: [string, any]) => (
                <Box key={key} sx={{ mb: 2, p: 2, background: 'rgba(255,255,255,0.05)', borderRadius: 1 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="h6">{token.symbol}</Typography>
                    <Chip 
                      label={token.change} 
                      color={token.change.startsWith('+') ? 'success' : 'error'}
                      size="small"
                    />
                  </Box>
                  <Typography variant="h4" className="gradient-text">
                    {token.balance}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {token.price}
                  </Typography>
                </Box>
              ))}
            </CardContent>
          </Card>
        </Grid>

        {/* Services Status */}
        <Grid item xs={12}>
          <Card className="glass fade-in">
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Services Status
              </Typography>
              <Grid container spacing={2}>
                {data?.services.map((service, index) => (
                  <Grid item xs={12} sm={6} md={4} key={index}>
                    <Box 
                      sx={{ 
                        p: 2, 
                        background: 'rgba(255,255,255,0.05)', 
                        borderRadius: 1,
                        border: '1px solid rgba(102, 126, 234, 0.2)',
                      }}
                    >
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                        <Typography variant="subtitle2">{service.name}</Typography>
                        <Chip 
                          label={service.status} 
                          color={service.status === 'online' ? 'success' : 'error'}
                          size="small"
                        />
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        Port: {service.port}
                      </Typography>
                    </Box>
                  </Grid>
                ))}
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Quick Actions */}
        <Grid item xs={12}>
          <Card className="glass fade-in">
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Quick Actions
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6} md={3}>
                  <Box 
                    sx={{ 
                      p: 3, 
                      textAlign: 'center',
                      background: 'rgba(102, 126, 234, 0.1)',
                      borderRadius: 2,
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        background: 'rgba(102, 126, 234, 0.2)',
                        transform: 'translateY(-2px)',
                      },
                    }}
                    onClick={() => window.location.href = '/transfer'}
                  >
                    <SendIcon sx={{ fontSize: 40, color: '#667eea', mb: 1 }} />
                    <Typography variant="h6">Transfer Tokens</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Send CRICE or MWT tokens
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <Box 
                    sx={{ 
                      p: 3, 
                      textAlign: 'center',
                      background: 'rgba(118, 75, 162, 0.1)',
                      borderRadius: 2,
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        background: 'rgba(118, 75, 162, 0.2)',
                        transform: 'translateY(-2px)',
                      },
                    }}
                    onClick={() => window.location.href = '/deploy'}
                  >
                    <CodeIcon sx={{ fontSize: 40, color: '#764ba2', mb: 1 }} />
                    <Typography variant="h6">Deploy Contract</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Deploy smart contracts
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <Box 
                    sx={{ 
                      p: 3, 
                      textAlign: 'center',
                      background: 'rgba(102, 126, 234, 0.1)',
                      borderRadius: 2,
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        background: 'rgba(102, 126, 234, 0.2)',
                        transform: 'translateY(-2px)',
                      },
                    }}
                    onClick={() => window.location.href = '/explorer'}
                  >
                    <ExploreIcon sx={{ fontSize: 40, color: '#667eea', mb: 1 }} />
                    <Typography variant="h6">Block Explorer</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Explore blockchain data
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <Box 
                    sx={{ 
                      p: 3, 
                      textAlign: 'center',
                      background: 'rgba(118, 75, 162, 0.1)',
                      borderRadius: 2,
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      '&:hover': {
                        background: 'rgba(118, 75, 162, 0.2)',
                        transform: 'translateY(-2px)',
                      },
                    }}
                    onClick={() => window.location.href = '/balances'}
                  >
                    <BalanceIcon sx={{ fontSize: 40, color: '#764ba2', mb: 1 }} />
                    <Typography variant="h6">View Balances</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Check token balances
                    </Typography>
                  </Box>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}

export default Dashboard
