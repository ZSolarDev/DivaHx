> [!WARNING]
> *This is NOT compatible with [**Diva Mod Manager**](https://github.com/TekkaGB/DivaModManager)! If you edit your mod list with DivaHx, Diva Mod Manager will overwrite it the next time it opens.*

> [!TIP]
> Report any issues in the [**Issues section**](https://github.com/ZSolarDev/DivaHx/issues). Also, all contributors are welcome!

<div align="center">
<img width="600" src="https://raw.githubusercontent.com/ZSolarDev/DivaHx/refs/heads/main/resources/logo/Logo-Flat.png">
<h2>
  <img src="https://img.shields.io/github/commit-activity/t/ZSolarDev/DivaHx?color=F6871F&style=for-the-badge">
  <img height="1000" src="https://img.shields.io/github/downloads/ZSolarDev/DivaHx/total?color=F6871F&style=for-the-badge">
  <img height="1000" src="https://img.shields.io/github/license/ZSolarDev/DivaHx?color=F6871F&style=for-the-badge">
</h2>

### *A mod manager for [Hatsune Miku: Project DIVA Mega Mix+](https://miku.sega.com/megamixplus/index.html) built in [Haxe](https://haxe.org).*
  
[***Welcome***](#welcome-to-divahx) • [***Setup***](#setup) • [***Features***](#features) • [***Planned Features***](#planned-features) • [***Credits***](#credits)
</div>

# Welcome to *DivaHx*
***DivaHx*** is a mod manager for ***Hatsune Miku: Project DIVA Mega Mix+***, allowing you to easily download, configure, and delete mods. ***DivaHx*** makes use of [***DIVA Mod Loader***](https://github.com/blueskythlikesclouds/DivaModLoader)(DML), a tool which loads mods for ***Project DIVA Mega Mix+***. Put simply, all ***DivaHx*** really does is install mods in your mods folder and edit DMLs `config.toml`.

<br>

# Setup
- Install ***DIVA Mod loader***. Refer to the [*Installation Guilde*](https://github.com/blueskythlikesclouds/DivaModLoader#Installation).
- Download and extract the latest release of ***DivaHx*** from the [*Releases page*](https://github.com/ZSolarDev/DivaHx/releases).
- Open `DivaHx.exe`. It will try to automatically find your ***Project DIVA Mega Mix+*** installation. If it can't find it, it opens to the *Configuration* menu. In that case, press the *Set MM+ Path* button. It will open a prompt where you can select the path to your ***Project DIVA Mega Mix+*** installation.
  - Don't know where it is? Refer to [*the section below.*](##where-to-find-your-hatsune-miku-project-diva-mega-mix-installation)
  - Once you have the path to your installation, go back to the prompt opened by ***DivaHx***, and patse in the path.
  - Click *Select Folder*.
  - Back in ***DivaHx***, click the *Apply* button.
- If it does find your ***Project DIVA Mega Mix+*** installation, it should open the *Mod Manager* menu. If that happens, you're good to go.
### Where to find your *Hatsune Miku: Project DIVA Mega Mix+* installation
- Open Steam.
  - Go to your Steam library. Either:
    - Right click on ***Hatsune Miku: Project DIVA Mega Mix+***.
    - Under the *Manage* section, press *Browse local files*.
  - Or you can:
    - Click on ***Hatsune Miku: Project DIVA Mega Mix+***.
    - Open the *Manage* menu(the gear icon at the right below the game banner).
    - Click *Properties...*
    - Go to the *Installed Files* section on the sidebar.
    - Press *Browse...*
    - Copy the path in file explorer.

<br>

# Features

<table> <!-- I'm actually a genius for figuring this out oh my god -->
  <tbody>
    <tr>
      <td>
        <h2>Downloading Mods</h2>
        <strong><em>DivaHx</em></strong> currently supports browsing mods off of <a href="https://divamodarchive.com"><strong><em>DIVA Mod Archive</em></strong></a>. You can:
        <ul>
          <li>Input search queries</li>
          <li>Change how it sorts mods</li>
          <li>Filter mods by their post type</li>
        </ul>
      </td>
    </tr>
    <tr>
      <td align="center"> 
        <kbd> <!-- I'm using the kbd tag cause it looks cool around images -->
          <img src="https://raw.githubusercontent.com/ZSolarDev/DivaHx/refs/heads/main/assets/Mod Browser.png">
        </kbd>
      </td>
    </tr>
    <tr>
      <td>
        You can click on a mod to see more info. In that menu, you can see:
        <ul>
          <li>The images uploaded with the mod</li>
          <li>The description</li>
          <li>If it's installed already</li>
          <li>Its dependencies</li>
          <li>If a dependency is installed already</li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

<br>

<table>
  <tbody>
    <tr>
      <td>
        <h2>Managing mods</h2>
        <strong><em>DivaHx</em></strong> Allows you to manage your mods by letting you:
        <ul>
          <li>Search for mods by name</li>
          <li>Change if a mod is enabled or disabled</li>
          <li>Delete a mod</li>
          <li>Configure a mod</li>
          <li>View a mods metadata</li>
          <li>See the size of a mod</li>
          <li>Drag and drop a mod to change its priority in relation to other mods</li>
        </ul>
      </td>
    </tr>
    <tr>
      <td align="center"> 
        <kbd>
          <img src="https://raw.githubusercontent.com/ZSolarDev/DivaHx/refs/heads/main/assets/Manage Mods.png">
        </kbd>
      </td>
    </tr>
    <tr>
      <td align="center">
        The <em>Actions...</em> button next to each mod opens this dropdown:
      </td>
    </tr>
    <tr>
      <td align="center"> 
        <kbd>
          <img src="https://raw.githubusercontent.com/ZSolarDev/DivaHx/refs/heads/main/assets/Actions Dropdown.png">
        </kbd>
      </td>
    </tr>
    <tr>
      <td align="center">
        Not all mods have extra options to configure or a <em>Mod Info</em> section. It all depends on the mods <code>config.toml</code> file, if it even has one.
        <br><br>
        You can also enable or disable all mods, and enable or disable if the console opens with the game.
      </td>
    </tr>
    <tr>
      <td align="center"> 
        <kbd>
          <img src="https://raw.githubusercontent.com/ZSolarDev/DivaHx/refs/heads/main/assets/Misc Config.png">
        </kbd>
      </td>
    </tr>
    <tr>
      <td align="center">
        There is also a <em>Play</em> section, that lets you launch <strong><em>Project DIVA Mega Mix+</em></strong> from either Steam or the Executable, but both run with mods.
      </td>
    </tr>
    <tr>
      <td align="center"> 
        <kbd>
          <img src="https://raw.githubusercontent.com/ZSolarDev/DivaHx/refs/heads/main/assets/Play.png">
        </kbd>
      </td>
    </tr>
  </tbody>
</table>

<br>

# Planned Features
- Mod sorting
- Mod filtering via all enabled/all disabled
- GameBanana mod browsing
- Mod creation helper
- Mod filtering via size
- Selecting multiple mods and either enabling/disabling them or deleting them at once

<br>

# Credits
| Name | Role |
| :--- | :--- |
| [***ZSolarDev***](https://github.com/ZSolarDev) | Main Developer |
| [***Aura***](https://github.com/Aura39) | Tester |
| ***Shay*** *(@sav1or_shay on discord)* | Tester  |
