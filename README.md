# Akashic Records - A Knowledge Repository App

## Description

Akashic Records is a mobile application designed to organize and present meaningful data, drawing inspiration from the concept of the Akashic Records as a repository of universal knowledge. The app offers offline access to data, features from various web sources, and tools to personalize the reading experience.

## Features

*   **Offline Mode:** Access your data even without an internet connection, leveraging local storage.
*   **Data Sourcing:** Fetch data from various web services and sources (scraping sites).
*   **Favorites:** Save and organize your preferred content.
*   **History:** Keep track of what you've read.
*   **Custom Themes:** Personalize the app's appearance to your liking.
*   **Reader:**
    *   **Customizable:** Adjust font, colors, themes, font sizes, line spacing, and text alignment for an optimal reading experience.

## TODO - Checklist

**Functionality & Features:**

*   [ ] Add advanced search functionality (keywords, filters, date ranges, etc.).
*   [ ] Implement filter settings for search results and content browsing.
*   [ ] **Reader Improvements:**
    *   [x] Add support for different text formats (e.g., Markdown, HTML).
    *   [ ] Implement text-to-speech functionality.
    *   [x] Add night mode and other theme options.
    *   [ ] Allow for customizable page turning animations.
*   [ ] Enhance data sourcing capabilities:
    *   [ ] Add support for more sources.
    *   [ ] Improve scraping accuracy and reliability.
    *   [ ] Implement background data updates.
*   [ ] **Content Management:**
    *   [ ] Allow users to create and organize content into notebooks or collections.
    *   [ ] Implement tagging system for easy content categorization.
*   [ ] **User Experience & Design:**
    *   [ ] Refine UI/UX design for improved usability.
    *   [ ] Add onboarding screens to guide new users.
    *   [ ] Implement a feedback mechanism for users to report issues and suggest improvements.
    *   [ ] Add notifications for updates and new content.

**Performance & Storage:**

*   [ ] Improve storage efficiency and loading speed. Optimize database queries and caching mechanisms.
*   [ ] Implement data compression techniques to reduce storage space.

**Data & Security:**

*   [ ] Integrate cloud backup for user data.
*   [ ] Implement robust data encryption to protect user privacy.

**Accessibility & Platform:**

*   [ ] Enhance accessibility features (e.g., screen reader compatibility, adjustable font sizes, high contrast mode).
*   [ ] Implement support for different languages and localization.

## Screenshots

*   ![Screenshot 1](lib/src/screenshots/scs1.png)
*   ![Screenshot 2](lib/src/screenshots/scs2.png)
*   ![Screenshot 3](lib/src/screenshots/scs3.png)
*   ![Screenshot 4](lib/src/screenshots/scs4.png)
*   ![Screenshot 5](lib/src/screenshots/scs5.png)
*   ![Screenshot 6](lib/src/screenshots/scs6.png)


## About the Name: Akashic Records

The name "Akashic Records" reflects the app's purpose of serving as a knowledge repository. It draws inspiration from the concept of Akashic Records, a philosophical term referring to a compendium of universal events, thoughts, and emotions. This aligns with the app's goal of organizing and presenting meaningful data, providing users with a centralized source of information and wisdom.

## Technologies Used

*   **Flutter:** For building a cross-platform mobile application (iOS and Android, linux, windows).
*   **Dart:** The programming language used with Flutter.
*   **SQLite:** For local data storage.
*   **Provider:** For state management within the Flutter application. 