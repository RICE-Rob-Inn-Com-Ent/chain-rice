import React, { useState } from 'react'
import {
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Box,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Chip,
} from '@mui/material'
import { Send as SendIcon, AccountBalance as BalanceIcon } from '@mui/icons-material'
import { useForm, Controller } from 'react-hook-form'
import toast from 'react-hot-toast'

interface TransferForm {
  fromAddress: string
  toAddress: string
  amount: string
  token: string
  memo?: string
}

const TokenTransfer: React.FC = () => {
  const [isLoading, setIsLoading] = useState(false)
  const [txHash, setTxHash] = useState<string | null>(null)

  const { control, handleSubmit, formState: { errors }, reset } = useForm<TransferForm>({
    defaultValues: {
      fromAddress: '',
      toAddress: '',
      amount: '',
      token: 'CRICE',
      memo: '',
    },
  })

  const onSubmit = async (data: TransferForm) => {
    setIsLoading(true)
    try {
      // Connect to real blockchain
      const response = await fetch('http://localhost:26657/broadcast_tx_commit', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          tx: btoa(JSON.stringify({
            type: 'transfer',
            from: data.fromAddress,
            to: data.toAddress,
            amount: data.amount,
            token: data.token,
            memo: data.memo
          }))
        })
      })

      if (!response.ok) {
        throw new Error('Transaction failed')
      }

      const result = await response.json()
      setTxHash(result.result.hash)
      
      toast.success('Transaction submitted successfully!')
      reset()
    } catch (error) {
      console.error('Transaction error:', error)
      toast.error('Transaction failed. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Box>
      <Typography variant="h4" className="gradient-text" sx={{ mb: 3 }}>
        Transfer Tokens
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card className="glass fade-in">
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <SendIcon sx={{ mr: 1, color: '#667eea' }} />
                <Typography variant="h6">Send Tokens</Typography>
              </Box>

              <form onSubmit={handleSubmit(onSubmit)}>
                <Grid container spacing={3}>
                  <Grid item xs={12}>
                    <Controller
                      name="fromAddress"
                      control={control}
                      rules={{ required: 'From address is required' }}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="From Address"
                          placeholder="chainrice1..."
                          error={!!errors.fromAddress}
                          helperText={errors.fromAddress?.message}
                          disabled={isLoading}
                        />
                      )}
                    />
                  </Grid>

                  <Grid item xs={12}>
                    <Controller
                      name="toAddress"
                      control={control}
                      rules={{ required: 'To address is required' }}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="To Address"
                          placeholder="chainrice1..."
                          error={!!errors.toAddress}
                          helperText={errors.toAddress?.message}
                          disabled={isLoading}
                        />
                      )}
                    />
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="token"
                      control={control}
                      render={({ field }) => (
                        <FormControl fullWidth>
                          <InputLabel>Token</InputLabel>
                          <Select
                            {...field}
                            label="Token"
                            disabled={isLoading}
                          >
                            <MenuItem value="CRICE">CRICE (urice)</MenuItem>
                            <MenuItem value="NORI">NORI (nori)</MenuItem>
                          </Select>
                        </FormControl>
                      )}
                    />
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="amount"
                      control={control}
                      rules={{ 
                        required: 'Amount is required',
                        pattern: {
                          value: /^\d+(\.\d+)?$/,
                          message: 'Please enter a valid amount'
                        }
                      }}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="Amount"
                          placeholder="0.00"
                          type="number"
                          error={!!errors.amount}
                          helperText={errors.amount?.message}
                          disabled={isLoading}
                        />
                      )}
                    />
                  </Grid>

                  <Grid item xs={12}>
                    <Controller
                      name="memo"
                      control={control}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="Memo (Optional)"
                          placeholder="Transaction memo..."
                          disabled={isLoading}
                        />
                      )}
                    />
                  </Grid>

                  <Grid item xs={12}>
                    <Button
                      type="submit"
                      variant="contained"
                      size="large"
                      fullWidth
                      disabled={isLoading}
                      startIcon={isLoading ? <CircularProgress size={20} /> : <SendIcon />}
                      sx={{
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        '&:hover': {
                          background: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
                        },
                      }}
                    >
                      {isLoading ? 'Sending...' : 'Send Transaction'}
                    </Button>
                  </Grid>
                </Grid>
              </form>

              {txHash && (
                <Alert severity="success" sx={{ mt: 3 }}>
                  <Typography variant="body2">
                    Transaction submitted successfully!
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    Transaction Hash: <Chip label={txHash} size="small" />
                  </Typography>
                </Alert>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card className="glass fade-in">
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <BalanceIcon sx={{ mr: 1, color: '#667eea' }} />
                <Typography variant="h6">Available Balances</Typography>
              </Box>

              <Box sx={{ mb: 3 }}>
                <Box sx={{ 
                  p: 2, 
                  background: 'rgba(102, 126, 234, 0.1)', 
                  borderRadius: 1,
                  mb: 2
                }}>
                  <Typography variant="subtitle2" color="text.secondary">
                    CRICE Token
                  </Typography>
                  <Typography variant="h5" className="gradient-text">
                    1,000.00 CRICE
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    ≈ $500.00
                  </Typography>
                </Box>

                <Box sx={{ 
                  p: 2, 
                  background: 'rgba(118, 75, 162, 0.1)', 
                  borderRadius: 1
                }}>
                  <Typography variant="subtitle2" color="text.secondary">
                    NORI Token
                  </Typography>
                  <Typography variant="h5" className="gradient-text">
                    2,500.00 NORI
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    ≈ $625.00
                  </Typography>
                </Box>
              </Box>

              <Alert severity="info">
                <Typography variant="body2">
                  Make sure you have sufficient balance and gas fees for the transaction.
                </Typography>
              </Alert>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}

export default TokenTransfer
