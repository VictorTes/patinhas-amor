# CLAUDE.md

## Project Overview

This repository contains a Flutter mobile application developed for the NGO **Patinhas e Amor**.

The application is used internally by the NGO team to manage reports of animal abandonment or abuse submitted by the public through a web platform.

The system architecture consists of:

* Public Web Platform (reporting occurrences and viewing animals for adoption)
* REST API (data storage and business logic)
* Flutter Mobile App (internal management used by the NGO)

The Flutter application interacts with the API to retrieve and update occurrences and register rescued animals.

---

# Development Guidelines

When generating code for this project, follow these principles:

1. Write clean and readable Dart code.
2. Keep UI code separated from business logic.
3. Use clear folder separation (screens, models, services).
4. Follow Flutter best practices.
5. Avoid large files; split logic into smaller components when possible.
6. Prefer simple and maintainable solutions over complex patterns.

---

# Architecture

The project follows a simple layered architecture:

UI → Services → Models

UI layer:

* Flutter widgets
* Screens

Services layer:

* Handles communication with the REST API
* Contains HTTP requests

Models layer:

* Data structures
* JSON serialization

---

# Folder Structure

The Flutter code must follow this structure:

```text
lib/
  main.dart
  screens/
  widgets/
  models/
  services/
  utils/
```

### screens

Contains application pages such as:

* occurrences list
* occurrence details
* register animal
* animals list

### widgets

Reusable UI components.

Examples:

* occurrence_card
* animal_card
* custom_button
* loading_indicator

### models

Dart classes representing API data.

Examples:

* Occurrence
* Animal

Each model should include JSON serialization methods.

### services

Classes responsible for API communication.

Examples:

* OccurrenceService
* AnimalService

---

# API Integration

The mobile app communicates with a REST API.

Example base URL:

http://localhost:3000

Typical endpoints:

GET /occurrences
PATCH /occurrences/:id/status
POST /animals
GET /animals

All responses are JSON.

---

# UI Guidelines

The UI should be simple and clean.

Design priorities:

* easy navigation
* clear information hierarchy
* readable text
* mobile-friendly layouts

Use:

* ListView for lists
* Cards for displaying occurrences and animals
* Forms for registering animals

---

# Error Handling

Always include:

* loading indicators
* basic error handling
* user feedback when operations fail

---

# Dependencies

Preferred packages:

http
provider or riverpod
image_picker

Avoid unnecessary dependencies.

---

# Code Style

Use clear naming conventions:

* camelCase for variables
* PascalCase for classes
* meaningful method names

Example:

fetchOccurrences()
updateOccurrenceStatus()
createAnimal()

---

# Development Priority

When implementing the application, follow this order:

1. Project setup
2. Models
3. API services
4. Occurrence list screen
5. Occurrence details screen
6. Register animal screen
7. Animals list screen
8. UI improvements
9. Error handling

---

# Context

This project is part of a **university extension initiative** aimed at helping a real NGO organize reports of animal abuse and manage rescued animals more effectively.
