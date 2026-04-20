import {
  Document, Packer, Paragraph, TextRun, HeadingLevel,
  AlignmentType, PageBreak, BorderStyle, Table, TableRow, TableCell,
  WidthType, ShadingType, UnderlineType
} from 'docx';
import { writeFileSync } from 'fs';

// ── Colour palette ────────────────────────────────────────────
const NAVY       = '0A2342';
const BLUE       = '1565C0';
const DARK       = '17202A';
const GREEN      = '1E8449';
const RED_       = 'C0392B';
const GREY       = '555555';
const LIGHT_GREY = 'F2F4F4';
const WHITE      = 'FFFFFF';
const GOLD       = 'D4AC0D';

// ── Helper: coloured heading ──────────────────────────────────
function sectionHeading(text, color = NAVY) {
  return new Paragraph({
    spacing: { before: 360, after: 120 },
    border: { bottom: { color: BLUE, size: 6, style: BorderStyle.SINGLE } },
    children: [
      new TextRun({
        text,
        bold: true,
        size: 32,
        color,
        font: 'Arial',
      }),
    ],
  });
}

function subHeading(text, color = BLUE) {
  return new Paragraph({
    spacing: { before: 240, after: 80 },
    children: [
      new TextRun({ text, bold: true, size: 26, color, font: 'Arial' }),
    ],
  });
}

function subSubHeading(text, color = DARK) {
  return new Paragraph({
    spacing: { before: 180, after: 60 },
    children: [
      new TextRun({ text, bold: true, underline: { type: UnderlineType.SINGLE }, size: 23, color, font: 'Arial' }),
    ],
  });
}

function body(text) {
  return new Paragraph({
    spacing: { before: 60, after: 80, line: 360 },
    children: [new TextRun({ text, size: 22, color: DARK, font: 'Calibri' })],
  });
}

function bullet(label, content) {
  return new Paragraph({
    spacing: { before: 40, after: 40, line: 320 },
    indent: { left: 720, hanging: 360 },
    children: [
      new TextRun({ text: '• ', bold: true, size: 22, color: BLUE, font: 'Calibri' }),
      new TextRun({ text: label ? `${label}: ` : '', bold: true, size: 22, color: DARK, font: 'Calibri' }),
      new TextRun({ text: content, size: 22, color: DARK, font: 'Calibri' }),
    ],
  });
}

function stageNote(text) {
  return new Paragraph({
    spacing: { before: 40, after: 40 },
    shading: { type: ShadingType.SOLID, color: 'E8F4FD', fill: 'E8F4FD' },
    children: [
      new TextRun({ text: `  ${text}  `, italics: true, size: 19, color: '2471A3', font: 'Calibri' }),
    ],
  });
}

function divider() {
  return new Paragraph({
    spacing: { before: 200, after: 200 },
    border: { bottom: { color: 'D5D8DC', size: 4, style: BorderStyle.SINGLE } },
    children: [new TextRun({ text: '' })],
  });
}

function qaQuestion(text) {
  return new Paragraph({
    spacing: { before: 220, after: 60 },
    shading: { type: ShadingType.SOLID, color: 'EBF5FB', fill: 'EBF5FB' },
    children: [
      new TextRun({ text: `  ${text}  `, bold: true, size: 22, color: NAVY, font: 'Calibri' }),
    ],
  });
}

function qaAnswer(text) {
  return new Paragraph({
    spacing: { before: 60, after: 100, line: 340 },
    indent: { left: 360 },
    children: [new TextRun({ text, size: 22, color: DARK, font: 'Calibri' })],
  });
}

function numbered(n, label, content) {
  return new Paragraph({
    spacing: { before: 80, after: 80, line: 320 },
    indent: { left: 720, hanging: 360 },
    children: [
      new TextRun({ text: `${n}.  `, bold: true, size: 22, color: BLUE, font: 'Calibri' }),
      new TextRun({ text: label ? `${label}: ` : '', bold: true, size: 22, color: DARK, font: 'Calibri' }),
      new TextRun({ text: content, size: 22, color: DARK, font: 'Calibri' }),
    ],
  });
}

function step(n, text) {
  return new Paragraph({
    spacing: { before: 50, after: 50, line: 300 },
    indent: { left: 720, hanging: 360 },
    children: [
      new TextRun({ text: `Step ${n}:  `, bold: true, size: 22, color: BLUE, font: 'Calibri' }),
      new TextRun({ text, size: 22, color: DARK, font: 'Calibri' }),
    ],
  });
}

function empty(lines = 1) {
  return Array.from({ length: lines }, () =>
    new Paragraph({ children: [new TextRun({ text: '' })] })
  );
}

// ══════════════════════════════════════════════════════════════
//  COVER PAGE
// ══════════════════════════════════════════════════════════════
const coverPage = [
  ...empty(6),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 0, after: 120 },
    children: [
      new TextRun({ text: 'BUSGO', bold: true, size: 80, color: NAVY, font: 'Arial' }),
    ],
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 0, after: 200 },
    children: [
      new TextRun({ text: 'Online Bus Travelling Management System', size: 40, color: BLUE, font: 'Arial' }),
    ],
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 0, after: 120 },
    border: {
      top: { color: BLUE, size: 8, style: BorderStyle.SINGLE },
      bottom: { color: BLUE, size: 8, style: BorderStyle.SINGLE },
    },
    children: [
      new TextRun({ text: '  VIVA PRESENTATION SCRIPT  ', bold: true, size: 48, color: WHITE, font: 'Arial' }),
    ],
    shading: { type: ShadingType.SOLID, color: NAVY, fill: NAVY },
  }),
  ...empty(2),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Role:  Front-End Developer', size: 28, color: DARK, font: 'Calibri', bold: true })],
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Technologies:  React 19 (TypeScript)  |  Flutter 3.8+  |  Dart', size: 24, color: GREY, font: 'Calibri' })],
    spacing: { before: 80, after: 80 },
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Applications:  Admin Web Panel  |  Passenger App  |  Driver App  |  Scanner App', size: 24, color: GREY, font: 'Calibri' })],
    spacing: { before: 0, after: 200 },
  }),
  ...empty(4),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: 'Total Estimated Presentation Time:  20 – 25 minutes', italics: true, size: 20, color: GREY, font: 'Calibri' })],
  }),
  new Paragraph({ children: [new PageBreak()] }),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 1 – OPENING
// ══════════════════════════════════════════════════════════════
const section1 = [
  sectionHeading('SECTION 1 — OPENING & INTRODUCTION'),
  stageNote('Duration: ~2 minutes  |  Stand confident, make eye contact with every panel member'),
  empty(1)[0],
  body('Good morning / afternoon, respected panel members.'),
  body('My name is [Your Name], and I served as the Front-End Developer for our group project titled BusGo — an Online Bus Travelling Management System designed specifically for the Sri Lankan public transport context.'),
  body('My contribution to this project spans two key technology areas:'),
  bullet('1', 'A React-based Admin Web Panel — a full-featured browser dashboard for transport administrators to manage the entire bus network in real time.'),
  bullet('2', 'Three Flutter mobile applications — a Passenger app, a Driver app, and a Ticket Scanner app — each serving a different user role in the bus system.'),
  empty(1)[0],
  body('In the next few minutes, I will walk you through the problem we solved, the architecture I designed and implemented, the key features of each application, the technology decisions I made, and the challenges I overcame during development.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 2 – PROBLEM STATEMENT
// ══════════════════════════════════════════════════════════════
const section2 = [
  sectionHeading('SECTION 2 — PROBLEM STATEMENT & PROJECT CONTEXT'),
  stageNote('Duration: ~2 minutes'),
  empty(1)[0],
  body('Sri Lanka\'s public bus network is one of the most heavily used transport systems in the country, yet it operates almost entirely without digital support. Commuters have no way to know where a bus is, how full it is, or when it will arrive. Drivers have no digital tools to report emergencies or log trips. Administrators manage fleets manually with no real-time visibility.'),
  empty(1)[0],
  new Paragraph({
    spacing: { before: 80, after: 80 },
    children: [new TextRun({ text: 'BusGo solves all three problems simultaneously.', bold: true, size: 24, color: NAVY, font: 'Calibri' })],
  }),
  empty(1)[0],
  body('The system provides:'),
  bullet('', 'Real-time bus tracking on live maps for both passengers and administrators.'),
  bullet('', 'A structured digital workflow for drivers to log trips, report emergencies, and receive route information.'),
  bullet('', 'A QR-code-based ticketing system for quick and paperless boarding.'),
  bullet('', 'A centralised admin control panel to oversee the full fleet, manage users, respond to emergencies, and maintain audit trails.'),
  empty(1)[0],
  body('The entire system is built around three Colombo metropolitan bus routes: Route 138 (Nugegoda to Colombo Fort), Route 163 (Rajagiriya to Maharagama), and Route 171 (Colombo 4 to Athurugiriya) — routes chosen because of their high ridership and geographic coverage of the Colombo district.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 3 – ARCHITECTURE
// ══════════════════════════════════════════════════════════════
const section3 = [
  sectionHeading('SECTION 3 — SYSTEM ARCHITECTURE OVERVIEW'),
  stageNote('Duration: ~2 minutes  |  Point to architecture diagram if available'),
  empty(1)[0],
  body('Before diving into my front-end work specifically, let me briefly describe how the overall system is structured so my work makes sense in context.'),
  empty(1)[0],
  body('BusGo follows a layered client-server architecture with four front-end applications connecting to a shared backend:'),
  empty(1)[0],
  bullet('Backend', 'A Node.js and Express.js REST API server, using Supabase as the cloud database and Supabase Realtime for live event broadcasting.'),
  bullet('Admin Panel', 'A React 19 + TypeScript web application — my work.'),
  bullet('Passenger Mobile App (BusGo Client)', 'A Flutter application for passengers — my work.'),
  bullet('Driver Mobile App (BusGo Drive)', 'A Flutter application for bus drivers — my work.'),
  bullet('Scanner App (BusGo Scanner)', 'A Flutter application for ticket conductors — my work.'),
  empty(1)[0],
  body('All four front-end applications communicate with the backend through a secured REST API, and the mobile apps also subscribe to Supabase Realtime for live bus location broadcasts.'),
  body('My role was entirely on the client layer. I was responsible for designing and implementing all four of these front-end applications, ensuring they were production-ready, responsive, and correctly connected to the backend API.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 4 – ADMIN PANEL
// ══════════════════════════════════════════════════════════════
const section4 = [
  sectionHeading('SECTION 4 — ADMIN WEB PANEL (REACT)'),
  stageNote('Duration: ~5–6 minutes  |  Open the admin panel live if possible'),

  subHeading('4.1  Technology Stack — Admin Panel'),
  body('For the Admin Panel, I chose the following stack:'),
  bullet('React 19 + TypeScript', 'React is the industry standard for building component-based web UIs. TypeScript was chosen to catch type errors at compile time, which is critical where API data shapes are complex.'),
  bullet('Vite', 'Used as the build tool for its extremely fast hot module replacement during development and optimised production bundles.'),
  bullet('React Router v7', 'For client-side routing with protected routes that redirect unauthenticated users.'),
  bullet('React Leaflet', 'For rendering interactive maps. Leaflet was chosen over Google Maps because it is open-source, requires no billing-enabled API key, and integrates with OpenStreetMap tiles.'),
  bullet('Axios', 'For API communication with the backend, wrapped in a central typed service layer.'),
  bullet('Lucide React', 'A consistent, lightweight icon library used throughout the UI.'),

  subHeading('4.2  Application Structure'),
  body('The admin panel is structured around a protected route system. Any user who is not authenticated is automatically redirected to the login page. Once logged in, the panel uses a persistent sidebar layout with a main content area, giving the feel of a native desktop application.'),
  empty(1)[0],
  body('The eight routes are:'),
  bullet('/admin/login', 'Authentication page'),
  bullet('/admin/dashboard', 'The main control centre'),
  bullet('/admin/fleet-map', 'Full-screen live map'),
  bullet('/admin/emergencies', 'Emergency alert management'),
  bullet('/admin/fleet', 'Bus fleet management'),
  bullet('/admin/users', 'User management (drivers, passengers, admins)'),
  bullet('/admin/routes', 'Route and bus stop management'),
  bullet('/admin/audit-logs', 'Admin action audit trail'),
  empty(1)[0],
  body('Authentication is implemented using React Context API. The AuthContext stores the admin session, handles login and logout, and persists the access token in localStorage. Every protected route checks the context before rendering — unauthenticated access always redirects to login.'),

  subHeading('4.3  Dashboard Page'),
  body('The Dashboard is the first screen an admin sees after logging in. It is designed to give an immediate, at-a-glance overview of the entire bus network.'),
  empty(1)[0],
  subSubHeading('Key Features:'),
  bullet('Live statistics cards', 'Show active buses, passengers today, pending emergency alerts, and standby buses. These figures auto-refresh on a polling interval so the admin always sees current data.'),
  bullet('Mini live map', 'An embedded Leaflet map showing all buses on the road. Each bus is a coloured circular marker: green = normal, amber = over 50% full, red = over 80% full or broken down. The number inside each marker shows the current passenger count.'),
  bullet('Notification panel', 'A bell icon in the header opens a sliding dropdown with recent system alerts, driver sign-ups, and emergency events. Admins can mark individual notifications as read or clear all.'),
  bullet('Active emergency strip', 'The most recent unresolved emergency alerts are listed directly on the dashboard, colour-coded by type — red for Medical, orange for Accident, purple for Criminal, orange-red for Breakdown.'),
  empty(1)[0],
  body('The key technical decision here was using polling with setInterval rather than WebSockets for statistics. The backend\'s data refresh rate is low enough that 10-second polling is sufficient, avoiding the complexity of a persistent WebSocket connection for non-critical UI elements.'),

  subHeading('4.4  Fleet Map Page'),
  body('The Fleet Map page is one of the most technically complex parts of the admin panel. It provides a full-screen, interactive view of all buses, their routes, and their stops.'),
  empty(1)[0],
  subSubHeading('Key Features:'),
  bullet('Live bus markers', 'Every active bus appears as a clickable marker. The marker size increases when selected so the admin can clearly see which bus they are inspecting.'),
  bullet('Route polylines', 'Selecting a route fetches road-accurate polylines from an OSRM (Open Source Routing Machine) API and draws them as coloured lines. Each route has a unique colour from a predefined palette.'),
  bullet('Bus stop markers', 'Bus stops for each route are drawn as circular markers along the polyline.'),
  bullet('Bus detail sidebar', 'Clicking any bus marker opens a side panel showing bus number, registration plate, route, passenger count and capacity, driver\'s name, phone, email, and star rating.'),
  bullet('Fly-to animation', 'Selecting a bus from the list triggers Leaflet\'s flyTo method, smoothly animating the map to centre on that bus.'),
  bullet('Default coordinates', 'If a bus has no GPS fix, it falls back to Colombo Fort coordinates (6.9271, 79.8612) rather than crashing the render.'),
  empty(1)[0],
  body('The most interesting engineering challenge here was the route polyline system. I designed a RouteLayer data structure that bundles the route ID, colour, stop list, and polyline coordinates together, loaded all routes in parallel using Promise.all, and rendered all layers atomically — preventing partial or flickering renders.'),

  subHeading('4.5  Emergencies Page'),
  body('This page allows administrators to view, filter, and respond to emergency alerts reported by drivers.'),
  bullet('Alert summary cards', 'Four stat cards show total, new, responded, and resolved alert counts.'),
  bullet('Filter panel', 'Admins can filter simultaneously by status (New / Responded / Resolved) and by emergency type (Medical / Accident / Criminal / Breakdown).'),
  bullet('Alert cards', 'Each alert shows a type icon colour-coded by severity, the time reported, location, and current status.'),
  bullet('Detail modal', 'Clicking an alert opens a full detail view.'),
  bullet('Status workflow', 'Admins transition alerts through: New → Responded → Resolved.'),
  bullet('Deploy bus', 'Admins can deploy a standby bus to an emergency location directly from this screen.'),
  bullet('View on Map', 'Navigates to the Fleet Map page for geographic context.'),
  empty(1)[0],
  body('The page polls the backend every 10 seconds so new emergencies submitted by drivers appear without manual refresh.'),

  subHeading('4.6  Fleet Management Page'),
  bullet('Fleet stats bar', 'Shows total, active, standby, in-repair, and broken-down bus counts.'),
  bullet('Filterable bus table', 'Filter all buses simultaneously by route and by status.'),
  bullet('Register new bus', 'A modal form registers a new bus and assigns it a route and driver.'),
  bullet('Edit bus', 'Reassign a bus to a different driver, update its registration, or change its route.'),
  bullet('Status update', 'Change a bus\'s operational status: Active, Standby, or In Repair.'),

  subHeading('4.7  User Management Page'),
  body('This page manages Drivers, Passengers, and Admins through a tabbed interface so all three user types are accessible from one screen.'),
  bullet('Driver tab', 'Shows all drivers with approval status. Admins can approve/reject new registrations, activate/suspend drivers, edit details, or delete accounts.'),
  bullet('Passenger tab', 'Admins can suspend, activate, or delete passenger accounts.'),
  bullet('Admin tab', 'Super-admins can create, edit, or remove administrator accounts.'),
  bullet('Search and filters', 'Each tab has a search bar plus status and route filters.'),
  bullet('Inline modal forms', 'All add/edit operations use modal dialogs — the user never navigates away.'),

  subHeading('4.8  Routes Page'),
  bullet('Route cards', 'Each route displays its number, name, origin, destination, and coloured accent.'),
  bullet('CRUD operations', 'Create new routes, edit existing ones, toggle active/inactive status, or delete.'),
  bullet('Stops panel', 'Clicking a route opens a StopsPanel component I built as a reusable sub-component. It lists all stops and allows adding, editing, or removing them.'),

  subHeading('4.9  Audit Logs Page'),
  body('Provides a complete, paginated record of every administrative action taken in the system.'),
  bullet('Action badges', 'Colour-coded by type: green for CREATE/APPROVE, red for DELETE/REJECT, blue for UPDATE/LOGIN, amber for DEPLOY, etc.'),
  bullet('Date range filter', 'Filter logs by custom date range.'),
  bullet('Admin & action filters', 'Filter by which admin performed the action and what type of action.'),
  bullet('Pagination', 'Paginated at 50 records per page to keep the UI responsive.'),
  empty(1)[0],
  body('This page is critical from a governance perspective. Every significant action — creating a user, deploying a bus, resolving an emergency — is recorded and traceable to a specific administrator.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 5 – FLUTTER APPS
// ══════════════════════════════════════════════════════════════
const section5 = [
  sectionHeading('SECTION 5 — FLUTTER MOBILE APPLICATIONS'),
  stageNote('Duration: ~6–7 minutes  |  Demo the apps or show screenshots'),

  subHeading('5.1  Technology Stack — Flutter Apps'),
  body('All three mobile apps are built with Flutter, using the following core packages:'),
  bullet('Flutter 3.8+ / Dart', 'Chosen for single-codebase Android and iOS support, native ARM compilation giving smooth 60fps animations, and a rich widget library.'),
  bullet('Provider', 'For state management. Lightweight, officially recommended by the Flutter team, and keeps UI separated cleanly from business logic.'),
  bullet('go_router', 'For declarative URL-based navigation, supporting deep links and the authenticated shell pattern.'),
  bullet('flutter_map', 'For rendering maps using OpenStreetMap tiles — fully open-source, no billing.'),
  bullet('Supabase Flutter', 'For subscribing to Realtime bus location broadcasts.'),
  bullet('Dio', 'For HTTP API communication, paired with a TokenService that injects JWT tokens into every request header.'),
  bullet('qr_flutter', 'For generating and rendering the passenger QR code.'),
  bullet('flutter_secure_storage', 'For securely persisting authentication tokens on the device keychain.'),
  bullet('google_fonts', 'For clean, consistent typography across all apps.'),
  empty(1)[0],
  body('All three apps share the same design language: dark navy primary (#0A2342), medium blue secondary (#1565C0), light grey surface (#F5F7FA) — a professional transit-system aesthetic.'),

  subHeading('5.2  BusGo Client — Passenger Mobile App'),
  body('The Passenger app is the primary public-facing product. It is used by Colombo bus commuters to find buses, track them live, report emergencies, and manage their digital identity.'),

  subSubHeading('Authentication Flow'),
  body('The app opens on a Splash Screen that checks for a saved token and navigates the user either to the home screen or to login. The Login Screen uses a staggered animation — each form element fades and slides in with a slight delay, giving a polished app-like feel rather than a plain static form.'),
  body('Remember Me functionality uses flutter_secure_storage to persist the refresh token in the device\'s keychain so users stay logged in between sessions. The Register screen handles new sign-ups with field validation, and Forgot Password sends a reset link via the backend.'),

  subSubHeading('Dashboard Screen'),
  bullet('Mini route map', 'A live-animated mini-map showing all three Colombo routes (138, 163, 171) with animated bus markers that move along the route polylines, simulating live bus positions.'),
  bullet('Nearby buses list', 'A scrollable list showing each bus\'s route number, direction, distance from the user, and current passenger count with a crowd indicator.'),
  bullet('BusCard widget', 'A reusable widget used on both the Dashboard and Search screens for visual consistency.'),
  bullet('CrowdIndicator widget', 'A custom widget I designed showing occupancy as a colour-coded bar — green (Low), amber (Moderate), or red (High).'),
  empty(1)[0],
  body('The bus animation uses Timer.periodic to advance each bus\'s position along its polyline every 3 seconds, creating a smooth real-time feel even without a live GPS signal.'),

  subSubHeading('Live Map Screen'),
  bullet('Real route polylines', 'The app calls the OSRM routing API to fetch road-accurate polylines for all three routes simultaneously.'),
  bullet('Animated live buses', 'Three bus markers move along the polylines using a custom interpolation algorithm I wrote — the bus position is calculated by finding which polyline segment the current progress falls into and linearly interpolating between those two coordinates.'),
  bullet('User location dot', 'A pulsing blue dot shows the user\'s position using a looping AnimationController.'),
  bullet('Bus selection', 'Tapping a bus marker reveals a bottom card with route name, crowd level, and status.'),

  subSubHeading('Route Search Screen'),
  bullet('Autocomplete', 'A destination text field with a live suggestion list that filters as the user types.'),
  bullet('Results', 'Shows all buses serving that destination with route numbers, directions, and crowd levels.'),

  subSubHeading('QR Card Screen'),
  body('Every passenger has a unique digital QR card. The screen fetches the user\'s profile from the UserProvider, generates a QR code using the passenger\'s unique QR string via qr_flutter, and displays it as a physical-looking card ready to be scanned by the conductor.'),

  subSubHeading('Emergency Screen'),
  body('Passengers can submit an emergency report with categorised type buttons and an optional free-text details field. Submissions are sent to the backend and appear immediately on the admin\'s Emergency Management page.'),

  subSubHeading('Additional Screens'),
  bullet('Alerts Screen', 'System notifications and service alerts.'),
  bullet('Ride History Screen', 'The passenger\'s past trips.'),
  bullet('Driver Rating Screen', 'Rate the driver after a trip.'),
  bullet('Profile Screen', 'View and edit account details.'),

  subHeading('5.3  BusGo Drive — Driver Mobile App'),
  body('The Driver app is a focused, distraction-minimised application that gives drivers exactly the information they need during their shift.'),

  subSubHeading('Driver Dashboard'),
  bullet('Passenger gauge', 'A large, visually prominent gauge shows current passenger count against total seat capacity (50 seats). Fill colour changes from green to amber to red as the bus fills up — instant status read without long screen time.'),
  bullet('Map preview', 'A compact flutter_map widget shows the driver\'s current position on the route.'),
  bullet('Next stop card', 'Prominently displays the name of the next upcoming stop.'),
  bullet('Trip stats', 'Running statistics including distance covered and time elapsed.'),

  subSubHeading('Active Trip Screen'),
  bullet('Full live map', 'Displays the bus\'s position, route polyline, and all upcoming stops.'),
  bullet('Trip information panel', 'Real-time trip statistics.'),
  bullet('SOS button', 'Prominently placed in the header — a single tap submits an emergency alert to the admin panel instantly.'),

  subSubHeading('Route Management Screens'),
  bullet('Route Selection', 'Drivers pick their assigned route before starting a trip.'),
  bullet('Route Map', 'Full-screen map view of the selected route with all stops.'),
  bullet('Trip Summary', 'Shown after a trip ends with complete trip statistics.'),
  bullet('My Rating', 'Drivers can view their average passenger rating and individual reviews.'),

  subSubHeading('Emergency Screen'),
  body('A dedicated emergency reporting screen with a large-button interface for quick use under stress. Drivers can report Medical, Accident, Criminal, or Breakdown emergencies.'),

  subHeading('5.4  BusGo Scanner — Ticket Scanner App'),
  body('The Scanner app is used by bus conductors to validate passenger QR tickets. It is the most focused of the three apps, with a single primary function.'),

  subSubHeading('Active Scanner Screen'),
  bullet('Animated scanning viewfinder', 'I implemented a custom animated viewfinder using two AnimationControllers. A scan line moves up and down continuously through the camera frame, and the viewfinder frame pulses rhythmically — both using looping Tween animations with CurvedAnimation easing. This provides the visual feedback of a professional barcode scanner without any third-party animation library.'),
  bullet('Dark overlay panels', 'Custom-painted dark panels surround the scan area to focus attention on the scan zone.'),
  bullet('Bottom info panel', 'Shows instructions and the scanner\'s current status.'),

  subSubHeading('Scan Result Screens'),
  bullet('Scan Success', 'Shown when a valid QR code is detected — displays the passenger\'s name, ticket information, and a green confirmation UI.'),
  bullet('Scan Error', 'Shown when an invalid or expired QR code is detected — clear error message and a retry button.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 6 – TECHNICAL DECISIONS
// ══════════════════════════════════════════════════════════════
const section6 = [
  sectionHeading('SECTION 6 — KEY TECHNICAL DECISIONS & JUSTIFICATIONS'),
  stageNote('Duration: ~3 minutes  |  Be ready to defend every choice listed here'),
  empty(1)[0],
  body('I want to highlight the key technical decisions I made that the panel may ask about:'),
  empty(1)[0],
  numbered(1, 'Why React for the Admin Panel and Flutter for mobile?',
    'React is the dominant library for complex, data-driven web applications. Its component model and ecosystem made it ideal for a multi-page dashboard with interactive tables, modals, and maps. Flutter was chosen for mobile because it compiles to native ARM code, giving smooth 60fps animations critical for map-heavy apps, and one codebase targets both Android and iOS.'),
  numbered(2, 'Why Provider over Bloc or Riverpod in Flutter?',
    'Provider is lightweight, integrates naturally with Flutter\'s widget tree via InheritedWidget, and is officially recommended by the Flutter team. Our app has five distinct state domains (Auth, Bus, Trip, User, Emergency) and Provider\'s multi-provider pattern kept each isolated and testable. Bloc or Riverpod would have added boilerplate without benefit at our scale.'),
  numbered(3, 'Why React Context API for auth, not Redux or Zustand?',
    'Authentication state is simple — authenticated or not — and changes rarely. Context API with a single AuthProvider is the right fit. Redux would have been over-engineering for this specific use case.'),
  numbered(4, 'Why OpenStreetMap / Leaflet / flutter_map instead of Google Maps?',
    'Google Maps requires a billing-enabled API key, introducing cost uncertainty. OpenStreetMap with Leaflet (web) and flutter_map (mobile) is fully open-source and provides the same tile quality for our Colombo use case. OSRM provides road-accurate polylines without any cost.'),
  numbered(5, 'Why Supabase Realtime for bus location instead of a custom WebSocket server?',
    'Supabase Realtime is a managed, scalable pub/sub infrastructure we connect to directly from Flutter without building and maintaining a custom WebSocket server. For bus location broadcasting — where the backend pushes to all subscribed clients — this pattern is exactly what Realtime is designed for.'),
  numbered(6, 'Why TypeScript over plain JavaScript for the admin panel?',
    'The admin panel consumes multiple API endpoints with complex data shapes: buses, drivers, passengers, emergency alerts, routes, stops, audit logs. TypeScript enforces correct handling of each shape at compile time. For a production-readiness goal, TypeScript was non-negotiable.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 7 – CHALLENGES
// ══════════════════════════════════════════════════════════════
const section7 = [
  sectionHeading('SECTION 7 — CHALLENGES & HOW I SOLVED THEM'),
  stageNote('Duration: ~2–3 minutes  |  This section demonstrates your problem-solving ability'),
  empty(1)[0],

  subSubHeading('Challenge 1: Animating buses along road-accurate polylines in Flutter'),
  body('The live map needed buses moving smoothly along actual road paths, not straight lines. The OSRM API returned polylines as lists of lat/lng coordinates, but animating a marker along hundreds of waypoints smoothly required a custom algorithm. I solved this by computing the cumulative distance of the polyline, then advancing a progress value (0.0 to 1.0) each timer tick. The current position is found by identifying which segment the progress falls into and linearly interpolating between those two coordinates. This gives smooth, continuous movement along the actual road shape.'),

  subSubHeading('Challenge 2: Displaying multiple route polylines on the admin panel map'),
  body('The admin panel needed multiple route polylines simultaneously, each with a different colour and each linked to its stops and buses. Loading all routes, stops, and road polylines involves multiple async API calls. I designed a RouteLayer data structure that bundles the route ID, colour, stop list, and polyline together, then loaded all routes in parallel using Promise.all. Once all data was ready, the map rendered all layers atomically — preventing partial or flickering renders.'),

  subSubHeading('Challenge 3: Keeping the admin panel responsive without a global state manager'),
  body('With eight pages each making their own API calls, I needed fresh data without over-fetching. I solved this with a consistent pattern: each page fetches its own data on mount via useEffect, uses polling (setInterval) only where live data is genuinely needed (Dashboard and Emergencies), and all service calls are centralised in a typed service layer so the same logic is never duplicated across pages.'),

  subSubHeading('Challenge 4: Making the scanner viewfinder feel professional'),
  body('A professional scanner screen needs precise visual feedback. I implemented two independent AnimationControllers — one for the scan line with easeInOut easing (2400ms), and one for the pulse glow with linear easing (1500ms). Layering these with Stack and Positioned widgets produced the professional scanning UI without any third-party animation library.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 8 – DEMO GUIDE
// ══════════════════════════════════════════════════════════════
const section8 = [
  sectionHeading('SECTION 8 — DEMO WALKTHROUGH GUIDE'),
  stageNote('Follow this order if demonstrating the system live during the viva'),
  empty(1)[0],
  subSubHeading('Admin Panel (Steps 1–7)'),
  step(1, 'Open the Admin Panel in a browser. Show the Login page. Log in with admin credentials.'),
  step(2, 'Walk through the Dashboard — point out the stats cards, the live map with coloured bus markers, the notification bell, and the emergency strip.'),
  step(3, 'Navigate to Fleet Map. Select a bus. Show the fly-to animation, the driver detail panel, and a route polyline overlaid on the map.'),
  step(4, 'Navigate to Emergencies. Show the filter controls (status and type filters). Click an alert and walk through the status workflow.'),
  step(5, 'Navigate to User Management. Show all three tabs (Drivers, Passengers, Admins). Open the Add Driver modal.'),
  step(6, 'Show the Routes page. Click a route to open the Stops panel.'),
  step(7, 'Show the Audit Logs page. Apply the date range filter. Point out the colour-coded action badges.'),
  empty(1)[0],
  subSubHeading('Mobile Apps (Steps 8–12)'),
  step(8, 'Open the Passenger app. Show the Dashboard with animated bus markers on the mini map.'),
  step(9, 'Navigate to the Live Map. Show all three animated bus markers moving along their Colombo routes and the pulsing user location dot.'),
  step(10, 'Navigate to the QR Card screen. Show the generated QR code card.'),
  step(11, 'Switch to the Driver app. Highlight the passenger gauge (colour-coded fill) and the SOS button in the trip header.'),
  step(12, 'Switch to the Scanner app. Activate the scanner — show the animated scan line and pulse glow on the viewfinder.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 9 – Q&A
// ══════════════════════════════════════════════════════════════
const section9 = [
  sectionHeading('SECTION 9 — ANTICIPATED VIVA QUESTIONS & ANSWERS'),
  stageNote('Study these answers carefully. Speak in your own words — do not recite verbatim.'),
  empty(1)[0],

  qaQuestion('Q1:  Why did you use React for the admin panel instead of a mobile app?'),
  qaAnswer('The admin panel is designed for desktop use by transport administrators who sit at workstations. A web application gives them a large screen with multiple data panels visible simultaneously — something a mobile screen cannot offer. React\'s component-based architecture also made it straightforward to build complex multi-panel layouts like the split-view Fleet Map page.'),

  qaQuestion('Q2:  What is the difference between the three Flutter apps?'),
  qaAnswer('They serve three completely different user roles. The Passenger app is for the general public — finding buses, tracking them live, and holding a QR ticket. The Driver app is for the person driving the bus — showing route information, passenger counts, and enabling SOS reporting during a trip. The Scanner app is for the conductor — its sole purpose is scanning QR codes to validate tickets. Each app is scoped tightly to its role to keep the UI focused and usable in its specific context.'),

  qaQuestion('Q3:  How does the QR ticketing system work end to end?'),
  qaAnswer('When a passenger registers, the backend generates a unique QR code string for their account and stores it in their profile. The Passenger app\'s QR Card screen fetches this string via the UserProvider and renders it as a QR image using qr_flutter. When the conductor opens the Scanner app and points it at the passenger\'s screen, the app reads the QR value and verifies it against the backend. A valid code shows the Scan Success screen; an invalid or expired code shows the Scan Error screen.'),

  qaQuestion('Q4:  How does the live map work? Is it actually real-time?'),
  qaAnswer('The system has two layers of real-time data. In the mobile apps, Supabase Realtime subscribes to bus location broadcasts pushed by the backend. Additionally, I implemented a client-side animation layer: even between Realtime updates, buses appear to move smoothly because the app animates markers along the known route polyline using timer-based interpolation. On the admin panel, bus positions are fetched through polling. For a production deployment with GPS hardware in buses, the Supabase Realtime channel would receive live GPS coordinates and broadcast them instantly to all subscribers.'),

  qaQuestion('Q5:  How did you handle authentication and security on the front end?'),
  qaAnswer('In the admin panel, authentication uses JWT tokens stored in localStorage. The AuthContext attaches the access token to every Axios request header. If a call returns 401 Unauthorised, the user is redirected to login. In the Flutter apps, tokens are stored using flutter_secure_storage, which uses the device\'s secure enclave (Android Keystore / iOS Keychain) — tokens cannot be read by other apps or through file system access. The TokenService wraps all token operations, and the ApiClient automatically injects the token into every Dio request header.'),

  qaQuestion('Q6:  What would you improve if you had more time?'),
  qaAnswer('Several things. First, integrate actual GPS hardware tracking through the driver app so real bus positions replace simulated movement. Second, add push notifications to the passenger app via Firebase Cloud Messaging so passengers are alerted when their bus is approaching. Third, implement offline support in the Flutter apps using a local SQLite cache — important for low-connectivity areas in suburban Sri Lanka. Fourth, add end-to-end tests for critical user flows like login, QR scanning, and emergency submission.'),

  qaQuestion('Q7:  How did you collaborate with your team as the front-end developer?'),
  qaAnswer('My work depended entirely on REST API contracts provided by the backend team. We agreed on API request and response formats early, and I formalised these contracts in a typed service layer — TypeScript interfaces in React, Dart model classes in Flutter. This meant I could develop front-end features against consistent interfaces even before backend endpoints were fully implemented, by using mock data services. Once the backend was ready, I swapped mock services for real API calls with minimal changes to the UI layer.'),
  divider(),
];

// ══════════════════════════════════════════════════════════════
//  SECTION 10 – CONCLUSION
// ══════════════════════════════════════════════════════════════
const section10 = [
  sectionHeading('SECTION 10 — CONCLUSION'),
  stageNote('Duration: ~1 minute  |  Finish strong — maintain eye contact, speak with confidence'),
  empty(1)[0],
  body('To summarise my contribution to BusGo:'),
  empty(1)[0],
  body('I designed and implemented four complete front-end applications — a React admin web panel and three Flutter mobile apps — all connected to a shared backend and all production-quality in terms of architecture, code organisation, and user experience.'),
  empty(1)[0],
  body('Across these applications, I built:'),
  bullet('', 'Real-time interactive maps with animated bus tracking across all four applications'),
  bullet('', 'A complete admin control centre covering fleet, user, emergency, and route management'),
  bullet('', 'A QR-code-based digital ticketing system linking the passenger and scanner apps'),
  bullet('', 'Emergency reporting for both drivers and passengers, wired directly to the admin panel'),
  bullet('', 'Secure JWT authentication on both web and mobile platforms'),
  bullet('', 'A professional, consistent design system across all four applications'),
  empty(1)[0],
  body('The project demonstrates that a production-ready, multi-platform transport management system can be built with modern open-source tooling at effectively zero infrastructure cost — a highly relevant consideration for public sector deployments in developing economies like Sri Lanka.'),
  empty(2)[0],
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 200, after: 200 },
    shading: { type: ShadingType.SOLID, color: NAVY, fill: NAVY },
    children: [
      new TextRun({ text: '  Thank you. I am happy to answer any questions.  ', bold: true, size: 28, color: WHITE, font: 'Arial' }),
    ],
  }),
  ...empty(3),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [
      new TextRun({ text: '— END OF SCRIPT —', italics: true, size: 20, color: GREY, font: 'Calibri' }),
    ],
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 80 },
    children: [
      new TextRun({ text: 'Total estimated presentation time: 20–25 minutes  |  Adjust pacing based on panel questions', italics: true, size: 18, color: GREY, font: 'Calibri' }),
    ],
  }),
];

// ══════════════════════════════════════════════════════════════
//  BUILD DOCUMENT
// ══════════════════════════════════════════════════════════════
const doc = new Document({
  styles: {
    default: {
      document: {
        run: { font: 'Calibri', size: 22, color: DARK },
        paragraph: { spacing: { line: 320 } },
      },
    },
  },
  sections: [
    {
      properties: {
        page: {
          margin: { top: 1080, bottom: 1080, left: 1080, right: 1080 },
        },
      },
      children: [
        ...coverPage,
        ...section1,
        ...section2,
        ...section3,
        ...section4,
        ...section5,
        ...section6,
        ...section7,
        ...section8,
        ...section9,
        ...section10,
      ],
    },
  ],
});

const buffer = await Packer.toBuffer(doc);
writeFileSync(
  'c:/Users/msi/Desktop/Online-Bus-Travelling-Management-Production-Ready/docs/BusGo_Viva_Presentation_Script.docx',
  buffer
);
console.log('Done: docs/BusGo_Viva_Presentation_Script.docx');
