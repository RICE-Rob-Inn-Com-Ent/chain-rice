// Allow importing global CSS files as side-effect without module declarations
declare module '*.css' {
  const content: any
  export default content
}
