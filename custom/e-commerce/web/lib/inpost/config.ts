'use client'

export interface InpostGeowidgetConfig {
  organizationId?: string
  geowidgetToken?: string
  scriptUrl: string
  primaryColor: string
  accentColor: string
}

export function getInpostGeowidgetConfig(): InpostGeowidgetConfig {
  // Nazwy dopasowane do Twoich zmiennych w .env.project:
  // INPOST_ORG_ID, INPOST_API_URL, INPOST_SHIPX_TOKEN, INPOST_GEOWIDGET_TOKEN
  const organizationId = process.env.INPOST_ORG_ID
  const geowidgetToken = process.env.INPOST_GEOWIDGET_TOKEN
  const scriptUrl =
    process.env.INPOST_API_URL ||
    'https://geowidget.easypack24.net/js/sdk-for-javascript.js'

  return {
    organizationId: organizationId || undefined,
    geowidgetToken: geowidgetToken || undefined,
    scriptUrl,
    // Kolory dopasowane do Meowtopii (header)
    primaryColor: '#A3D9A5',
    accentColor: '#B4C588'
  }
}


