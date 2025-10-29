# Rice Marketing Site - Features

## 🎯 Overview

Public-facing marketing website for Rice AI and GiPT-1 platform.

**URL**: http://localhost:3002

---

## 📄 Pages

### 1. Home (`/`)

**Hero Section:**

- Eye-catching headline: "One Model, Six Superpowers"
- Animated gradient text
- 2 CTA buttons (Try Demo, View Pricing)
- Stats: 6 models, 1 interface, ∞ possibilities

**Features Showcase:**

- 6 god cards with icons, titles, descriptions
- Gradient backgrounds matching each god
- Hover animations

**Tech Stack Grid:**

- 8 technology badges
- Mistral, SD, LLaVA, CodeLlama, etc.

**Final CTA:**

- "Ready to Experience GiPT-1?"
- Try Demo / Contact Sales buttons

---

### 2. Pricing (`/pricing`)

**Subscription Plans:**

- **Starter** - $49/month
  - 1,000 API calls
  - Text generation only
  - Community support
- **Pro** - $199/month (MOST POPULAR)
  - 20,000 API calls
  - Full multimodal (all 6 gods)
  - Priority support
  - Custom LoRA training
- **Enterprise** - Custom pricing
  - Unlimited calls
  - On-premise deployment
  - Dedicated infrastructure
  - 24/7 support

**Development Services:**

- Web Development - from $5,000
- Mobile Apps - from $15,000
- AI Integration - from $8,000
- Backend API - from $10,000

**FAQ Section:**

- 4 common questions answered
- Expandable details
- Startup discounts info

**CTA:**

- "Need a custom solution?" contact form link

---

### 3. About (`/about`)

**Mission Statement:**

- Why GiPT-1 exists
- Vision for accessible AI

**Technology Explanation:**

- LoRA Fusion
- 6GB VRAM optimization
- Multi-backend architecture
- Open source foundation

**Team:**

- Code-Rice introduction
- GitHub & npm links

**Values:**

- Privacy First
- Performance
- Open Source

---

### 4. Demo (`/demo`)

**Interactive Demo Interface:**

4 modes to choose from:

1. **Text Generation** (Thoth, Maat, Isis)
2. **Image Creation** (Ra - Stable Diffusion)
3. **Vision Analysis** (Bastet - LLaVA)
4. **Code Generation** (Khnum - CodeLlama)

**Features:**

- Mode selection buttons
- Input area (textarea or file upload)
- Generate button with loading state
- Output display
- Mock responses (real API in admin panel)

**Info Note:**

- Links to admin panel for full access
- Explains this is a demo version

---

### 5. Contact (`/contact`)

**Contact Form:**

- Name (required)
- Email (required)
- Company (optional)
- Interest dropdown:
  - General inquiry
  - GiPT-1 Subscription
  - Enterprise solution
  - Custom development
  - AI integration
  - LoRA training service
- Message (required)
- Submit with animation

**Direct Contact:**

- Email: hello@rice-ai.com
- GitHub: github.com/rice-mono
- Twitter: @RiceAI

**Quick Links:**

- Admin Panel (port 3001)
- Documentation
- NPM Package

**Response Times:**

- General: 24 hours
- Enterprise: Same day
- Support: 1-4 hours

---

## 🎨 Design Features

### Consistent Branding

- **Colors**: Purple/pink gradients (matching admin)
- **Typography**: Bold headings, clean body text
- **Icons**: @iconify/react throughout
- **Animations**: Smooth transitions, hover effects

### Responsive

- Mobile-first design
- Breakpoints: sm, md, lg
- Hamburger menu on mobile (if added)
- Touch-friendly buttons

### Accessibility

- Semantic HTML
- ARIA labels
- Keyboard navigation
- Focus states

---

## 🔗 Navigation

**Header (all pages):**

- Logo (links to home)
- Nav links: Home, Pricing, About, Demo, Contact
- Admin Panel button (opens 3001 in new tab)
- Try Demo CTA

**Footer (all pages):**

- Brand info
- Product links
- Resources (docs, GitHub, npm)
- Contact info
- Social media icons
- Copyright

---

## 🚀 Performance

### Optimizations

- Code splitting (React Router lazy loading)
- Image optimization
- CSS purging (Tailwind)
- Tree shaking
- Minification

### Metrics (estimated)

- First Contentful Paint: < 1s
- Time to Interactive: < 2s
- Bundle size: ~300 KB
- Lighthouse score: 90+

---

## 🔧 Technical Stack

- **Framework**: Vite + React 18
- **Router**: React Router v6
- **Styling**: Tailwind CSS
- **Icons**: Iconify
- **Components**: @rice-mono/ui-kit (shared)
- **Language**: TypeScript
- **Build**: Vite (fast HMR)

---

## 📦 Deployment

### Build for production

```bash
cd .frontend/web-marketing
yarn build
```

Output: `dist/` folder (static files)

### Deploy to

- **Vercel** (recommended for Vite)
- **Netlify**
- **AWS S3 + CloudFront**
- **GitHub Pages**
- **Any static host**

### Environment variables

Create `.env.production`:

```env
VITE_API_URL=https://api.rice-ai.com
VITE_ADMIN_URL=https://admin.rice-ai.com
```

---

## 🎯 Future Enhancements

- [ ] Blog section
- [ ] Customer testimonials
- [ ] Video demos
- [ ] Live chat integration
- [ ] Analytics (Google Analytics, Plausible)
- [ ] A/B testing
- [ ] Email capture (newsletter)
- [ ] Localization (PL/EN switch)

---

## ✅ Ready to Launch!

Marketing site is production-ready with:

- Beautiful landing page
- Clear pricing structure
- Interactive demo
- Easy contact
- SEO optimization
- Shared component library

**Next:** Deploy to Vercel and start getting customers! 🚀
