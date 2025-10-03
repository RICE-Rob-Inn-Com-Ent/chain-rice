import React from 'react'
import { Typography, Box } from '@mui/material'

const BlockExplorer: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" className="gradient-text" sx={{ mb: 3 }}>
        Block Explorer
      </Typography>
      <Typography variant="body1">
        Block explorer page - Coming soon!
      </Typography>
    </Box>
  )
}

export default BlockExplorer
