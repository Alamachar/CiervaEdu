import os
import shutil
import subprocess

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Gio", "2.0")
from gi.repository import Gtk, GdkPixbuf, Gio

SYSTEM_BG_DIR = "/usr/share/backgrounds"
USER_BG_DIR = os.path.expanduser("~/.local/share/backgrounds")


class FondoApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Galería de Fondos")
        self.set_default_size(800, 600)
        
        # Configurar icono de la aplicación (debe coincidir con StartupWMClass en .desktop)
        self.set_wmclass("wallpaperapp", "Fondos")
        
        # Establecer el icono de la aplicación
        icon_path = "/opt/ciervaedu/wallpaperapp/icon.png"
        if os.path.exists(icon_path):
            try:
                self.set_icon_from_file(icon_path)
            except Exception as e:
                print(f"No se pudo cargar el icono: {e}")
                # Fallback a icono del sistema
                try:
                    self.set_icon_name("applications-graphics")
                except:
                    pass
        else:
            # Si no encuentra el icono, usar uno del tema del sistema
            try:
                self.set_icon_name("applications-graphics")
            except:
                try:
                    self.set_icon_name("image-x-generic")
                except:
                    pass

        # Obtener temas disponibles
        self.themes = [
            theme
            for theme in os.listdir("/usr/share/themes")
            if os.path.isdir(os.path.join("/usr/share/themes", theme))
        ]

        # Obtener navegadores disponibles
        self.browsers = self.get_available_browsers()

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)

        # Barra de herramientas
        self._setup_toolbar(vbox)
        
        # Notebook (pestañas)
        notebook = Gtk.Notebook()
        vbox.pack_start(notebook, True, True, 0)
        
        # Pestaña de fondos del sistema
        self._setup_system_backgrounds(notebook)
        
        # Pestaña de fondos de usuario
        self._setup_user_backgrounds(notebook)
        
        # Pestaña de otros ajustes
        self._setup_other_settings_tab(notebook)

    def _setup_toolbar(self, parent):
        toolbar = Gtk.Box(spacing=10)
        parent.pack_start(toolbar, False, False, 0)

        btn_add = Gtk.Button(
            label="Añadir Fondo",
            image=Gtk.Image.new_from_icon_name("list-add", Gtk.IconSize.BUTTON)
        )
        btn_add.connect("clicked", self.on_add_background)
        toolbar.pack_start(btn_add, False, False, 0)

        btn_delete = Gtk.Button(
            label="Eliminar Fondo",
            image=Gtk.Image.new_from_icon_name("list-remove", Gtk.IconSize.BUTTON)
        )
        btn_delete.connect("clicked", self.on_delete_background)
        toolbar.pack_start(btn_delete, False, False, 0)

    def _setup_system_backgrounds(self, notebook):
        self.system_store = Gtk.ListStore(str, GdkPixbuf.Pixbuf)
        self.load_images(SYSTEM_BG_DIR, self.system_store)
        
        iconview_system = Gtk.IconView.new_with_model(self.system_store)
        iconview_system.set_pixbuf_column(1)
        iconview_system.set_item_width(128)
        iconview_system.connect("item-activated", self.on_image_selected)
        
        sw_system = Gtk.ScrolledWindow()
        sw_system.add(iconview_system)
        notebook.append_page(sw_system, Gtk.Label(label="Fondos del Sistema"))

    def _setup_user_backgrounds(self, notebook):
        if not os.path.exists(USER_BG_DIR):
            os.makedirs(USER_BG_DIR)
            
        self.user_store = Gtk.ListStore(str, GdkPixbuf.Pixbuf)
        self.iconview_user = Gtk.IconView.new_with_model(self.user_store)
        self.iconview_user.set_pixbuf_column(1)
        self.iconview_user.set_item_width(128)
        self.iconview_user.connect("item-activated", self.on_image_selected)
        
        sw_user = Gtk.ScrolledWindow()
        sw_user.add(self.iconview_user)
        notebook.append_page(sw_user, Gtk.Label(label="Fondos de Usuario"))
        self.load_images(USER_BG_DIR, self.user_store)

    def _setup_other_settings_tab(self, notebook):
        settings_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        settings_box.set_margin_left(20)
        settings_box.set_margin_right(20)
        settings_box.set_margin_top(20)
        settings_box.set_margin_bottom(20)
        notebook.append_page(settings_box, Gtk.Label(label="Otros ajustes"))

        # Sección de Tema
        theme_frame = Gtk.Frame(label="Tema del Sistema")
        theme_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        theme_box.set_margin_left(10)
        theme_box.set_margin_right(10)
        theme_box.set_margin_top(10)
        theme_box.set_margin_bottom(10)
        theme_frame.add(theme_box)

        self.theme_combo = Gtk.ComboBoxText()
        for theme in self.themes:
            self.theme_combo.append_text(theme)

        active_theme = self.get_active_theme()
        if active_theme:
            self.theme_combo.set_active(self.themes.index(active_theme))

        self.theme_combo.connect("changed", self.on_theme_changed)
        theme_box.pack_start(Gtk.Label(label="Seleccionar tema:"), False, False, 0)
        theme_box.pack_start(self.theme_combo, False, False, 0)

        settings_box.pack_start(theme_frame, False, False, 0)

        # Sección de Navegador
        browser_frame = Gtk.Frame(label="Navegador Predeterminado")
        browser_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        browser_box.set_margin_left(10)
        browser_box.set_margin_right(10)
        browser_box.set_margin_top(10)
        browser_box.set_margin_bottom(10)
        browser_frame.add(browser_box)

        self.browser_combo = Gtk.ComboBoxText()
        for browser in self.browsers:
            self.browser_combo.append_text(browser['name'])

        active_browser = self.get_default_browser()
        if active_browser:
            browser_names = [b['name'] for b in self.browsers]
            if active_browser in browser_names:
                self.browser_combo.set_active(browser_names.index(active_browser))

        self.browser_combo.connect("changed", self.on_browser_changed)
        browser_box.pack_start(Gtk.Label(label="Seleccionar navegador:"), False, False, 0)
        browser_box.pack_start(self.browser_combo, False, False, 0)

        settings_box.pack_start(browser_frame, False, False, 0)

    def get_available_browsers(self):
        """Obtiene la lista de navegadores disponibles en el sistema"""
        browsers = []
        common_browsers = [
            {'name': 'Firefox', 'command': 'firefox', 'desktop': 'firefox.desktop'},
            {'name': 'Google Chrome', 'command': 'google-chrome', 'desktop': 'google-chrome.desktop'},
            {'name': 'Microsoft Edge', 'command': 'microsoft-edge', 'desktop': 'microsoft-edge.desktop'},
        ]
        
        for browser in common_browsers:
            try:
                # Verificar si el comando existe
                subprocess.run(['which', browser['command']], 
                             check=True, capture_output=True)
                browsers.append(browser)
            except subprocess.CalledProcessError:
                pass
        
        return browsers

    def get_default_browser(self):
        """Obtiene el navegador predeterminado actual"""
        try:
            result = subprocess.check_output([
                'xdg-settings', 'get', 'default-web-browser'
            ]).decode('utf-8').strip()
            
            # Buscar el navegador correspondiente
            for browser in self.browsers:
                if browser['desktop'] == result:
                    return browser['name']
            return None
        except subprocess.CalledProcessError:
            return None

    def get_active_theme(self):
        try:
            current_theme = subprocess.check_output([
                "gsettings", "get",
                "org.gnome.desktop.interface", "gtk-theme"
            ]).decode("utf-8").strip().strip("'")
            return current_theme
        except subprocess.CalledProcessError:
            return None

    def find_images_recursive(self, folder):
        """Busca imágenes de manera recursiva en una carpeta"""
        image_files = []
        supported_extensions = (".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp", ".tiff", ".tif")
        
        try:
            for root, dirs, files in os.walk(folder):
                for file in files:
                    if file.lower().endswith(supported_extensions):
                        full_path = os.path.join(root, file)
                        image_files.append(full_path)
        except (OSError, PermissionError) as e:
            print(f"Error al acceder a la carpeta {folder}: {e}")
        
        return sorted(image_files)

    def load_images(self, folder, liststore):
        """Carga imágenes de manera recursiva en el liststore"""
        liststore.clear()
        
        if not os.path.exists(folder):
            print(f"La carpeta {folder} no existe")
            return
        
        print(f"Buscando imágenes en {folder} (búsqueda recursiva)...")
        image_files = self.find_images_recursive(folder)
        
        print(f"Encontradas {len(image_files)} imágenes")
        
        for image_path in image_files:
            pixbuf = self.get_thumbnail(image_path)
            if pixbuf:
                liststore.append([image_path, pixbuf])
            else:
                print(f"No se pudo cargar miniatura para: {image_path}")

    def get_thumbnail(self, image_path):
        try:
            return GdkPixbuf.Pixbuf.new_from_file_at_scale(
                image_path, 128, 128, True
            )
        except Exception as e:
            print(f"Error al crear miniatura para {image_path}: {e}")
            return None

    def on_image_selected(self, iconview, treepath):
        model = iconview.get_model()
        tree_iter = model.get_iter(treepath)
        image_path = model.get_value(tree_iter, 0)
        self.set_background(image_path)

    def set_background(self, image_path):
        settings = Gio.Settings.new("org.gnome.desktop.background")
        abs_path = os.path.abspath(image_path)
        
        # Cambiar fondo para modo claro y oscuro
        settings.set_string("picture-uri", f"file://{abs_path}")
        subprocess.run([
            "gsettings", "set",
            "org.gnome.desktop.background",
            "picture-uri-dark", f"file://{abs_path}"
        ])
        settings.apply()
        print(f"Fondo cambiado a: {image_path}")

    def on_add_background(self, widget):
        dialog = Gtk.FileChooserDialog(
            title="Selecciona una imagen",
            parent=self,
            action=Gtk.FileChooserAction.OPEN
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OPEN, Gtk.ResponseType.OK
        )
        
        filtro = Gtk.FileFilter()
        filtro.set_name("Imágenes")
        filtro.add_pattern("*.png")
        filtro.add_pattern("*.jpg")
        filtro.add_pattern("*.jpeg")
        filtro.add_pattern("*.bmp")
        filtro.add_pattern("*.gif")
        filtro.add_pattern("*.webp")
        filtro.add_pattern("*.tiff")
        filtro.add_pattern("*.tif")
        dialog.add_filter(filtro)

        if dialog.run() == Gtk.ResponseType.OK:
            origen = dialog.get_filename()
            destino = os.path.join(USER_BG_DIR, os.path.basename(origen))
            shutil.copy(origen, destino)
            self.load_images(USER_BG_DIR, self.user_store)

        dialog.destroy()

    def on_delete_background(self, widget):
        selection = self.iconview_user.get_selected_items()
        if selection:
            treepath = selection[0]
            model = self.iconview_user.get_model()
            tree_iter = model.get_iter(treepath)
            image_path = model.get_value(tree_iter, 0)
            
            # Verificar que la imagen esté en la carpeta de usuario antes de eliminar
            if image_path.startswith(USER_BG_DIR):
                try:
                    os.remove(image_path)
                    self.load_images(USER_BG_DIR, self.user_store)
                    print(f"Imagen eliminada: {image_path}")
                except OSError as e:
                    print(f"Error al eliminar la imagen: {e}")
            else:
                print("Solo se pueden eliminar imágenes de la carpeta de usuario")

    def on_theme_changed(self, widget):
        selected_theme = self.theme_combo.get_active_text()
        if not selected_theme:
            return

        # Cambiar tema GTK
        settings = Gio.Settings.new("org.gnome.desktop.interface")
        settings.set_string("gtk-theme", selected_theme)
        
        # Cambiar esquema de color
        color_scheme = "prefer-dark" if "dark" in selected_theme.lower() else "default"
        subprocess.run([
            "gsettings", "set",
            "org.gnome.desktop.interface",
            "color-scheme", color_scheme
        ])
        
        # Cambiar tema de iconos
        subprocess.run([
            "gsettings", "set",
            "org.gnome.desktop.interface",
            "icon-theme", selected_theme
        ])
        
        print(f"Tema cambiado a: {selected_theme} ({color_scheme})")

    def on_browser_changed(self, widget):
        selected_browser_name = self.browser_combo.get_active_text()
        if not selected_browser_name:
            return

        # Encontrar el navegador seleccionado
        selected_browser = None
        for browser in self.browsers:
            if browser['name'] == selected_browser_name:
                selected_browser = browser
                break

        if selected_browser:
            try:
                # Establecer como navegador predeterminado
                subprocess.run([
                    'xdg-settings', 'set', 'default-web-browser', 
                    selected_browser['desktop']
                ], check=True)
                print(f"Navegador predeterminado cambiado a: {selected_browser_name}")
            except subprocess.CalledProcessError as e:
                print(f"Error al cambiar navegador predeterminado: {e}")


if __name__ == "__main__":
    app = FondoApp()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()