import tkinter as tk
from tkinter import ttk, messagebox
import ffe as saf  # sas-appfitter interface
import pandas as pd
from os import path
import time


class MainApplication(ttk.Frame):
    """ Runs the GUI """
    def __init__(self, parent, *args, **kwargs):
        ttk.Frame.__init__(self, parent, *args, **kwargs)
        self.root = parent
        self.refresh_period = 300
        self.mute = False
        self.paused = False
        self.refresh_string = tk.StringVar(self, self.refresh_period)

        self.root.option_add('*tearOff', 'FALSE')  # menu bar stuck in place
        self.menu = tk.Menu(self.root)
        self.menu_file = tk.Menu(self.menu)
        self.menu_file.add_command(label='Exit', command=self.on_quit)
        self.menu.add_cascade(menu=self.menu_file, label='File')
        self.root.config(menu=self.menu)

        self.title = ttk.Label(text="Python Demo")
        self.title.grid(row=1, column=1, columnspan=3)
        self.title.config(font=("Arial", 36))

        self.dropdown_area = ttk.Frame(self.root)
        self.dropdown_area.grid(row=2, column=1, sticky='nw')

        self.plot_area = tk.Canvas(self.dropdown_area, width=666, height=666)
        self.plot_area.grid(row=3, column=1, columnspan=3, rowspan=3)
        self.sas_plot = tk.PhotoImage()

        self.axis_array = ["Name", "Sex", "Age", "Height", "Weight"]
        self.xaxis = ttk.Combobox(self.dropdown_area, values=self.axis_array)
        self.xaxis.grid(row=1, column=2, sticky='nw')
        self.yaxis = ttk.Combobox(self.dropdown_area, values=self.axis_array)
        self.yaxis.grid(row=2, column=2, sticky='nw')
        self.xaxis_label = ttk.Label(self.dropdown_area, text="X axis")
        self.xaxis_label.grid(row=1, column=1, sticky='e')
        self.yaxis_label = ttk.Label(self.dropdown_area, text="Y axis")
        self.yaxis_label.grid(row=2, column=1, sticky='e')

        self.fav_area = ttk.Frame(self.root)
        self.fav_area.grid(row=1, column=2, rowspan=7)

        self.fav_label = ttk.Label(self.fav_area, text="Favourites")
        self.fav_label.grid(row=1, column=1)

        def select_favourite(evt):
            w = evt.widget
            index = int(w.curselection()[0])
            favourite_split = w.get(index).split()
            self.yaxis.set(favourite_split[0])
            self.xaxis.set(favourite_split[2])

        self.favbox = tk.Listbox(self.fav_area)
        self.favbox.grid(row=2, column=1, rowspan=3, sticky='w')
        self.favbox.bind(sequence='<<ListboxSelect>>', func=select_favourite)

        self.button_area = ttk.Frame(self.fav_area)
        self.button_area.grid(row=6, column=1)

        self.debug_button = ttk.Button(self.button_area, text='Debug', command=self.debug)
        self.debug_button.grid(row=1, column=1, sticky='nw')

        self.run_button = ttk.Button(self.button_area, text='Run in SAS', command=self.run_sas)
        self.run_button.grid(row=2, column=1, sticky='nw')

        saf.setup_datastore(name='MyStoredData', targ='appconfig')
        self.refresh()

    def debug(self):
        self.refresh()
        None

    def refresh(self):
        self.plot_area.create_image(10, 10, anchor='nw', image=self.sas_plot)

        self.favbox.delete(0, tk.END)
        from_datastore = saf.get_datastore_dset('MyStoredData', 'FAVOURITES')
        for fav in from_datastore.to_dict('records'):
            self.favbox.insert('end', '{0} vs {1}'.format(fav['yaxis'].title(), fav['xaxis'].title()))

        return None

    def run_sas(self):
        list_of_dicts = []
        self.sas_plot = tk.PhotoImage()

        if not self.xaxis.get() or not self.yaxis.get():
            print('Need to have both axes selected')
        else:
            list_of_dicts.append({"xaxis": self.xaxis.get(), "yaxis": self.yaxis.get()})
            d = pd.io.json.json_normalize(list_of_dicts)  # turn list of dictionaries into DataFrame
            saf.set_stream_dset('MyData', d)

            submit_time = time.time()
            saf.run_sas_process('genericprogram')
            is_successful_run = saf.wait_for_stream_response(submit_time)

            if is_successful_run:
                print(saf.SUCCESSSTRING)
                from_sas = saf.get_stream_dset('MyData')  # read from SAS stream
                d = from_sas.to_dict('records')[0]  # first element in list of dictionaries
                if 'plotpath' in d:
                    if path.exists(d['plotpath']):
                        self.sas_plot = tk.PhotoImage(file=d['plotpath'])
                    else:
                        print(d['plotpath'] + ' does not exist')
            else:
                messagebox.showinfo(
                    "Did not receive response",
                    "Timed out waiting for response from SAS process after {0} seconds".format(saf.TIMEOUTSECS))

        self.refresh()

    def on_quit(self):
        if messagebox.askokcancel("Quit", "Do you want to quit?"):
            saf.teardown_datastore('MyStoredData')
            self.root.destroy()


if __name__ == "__main__":
    root = tk.Tk()  # make window
    app = MainApplication(root)
    root.mainloop()  # fire up the GUI
