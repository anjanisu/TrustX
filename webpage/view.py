from flask import Blueprint, render_template

views = Blueprint('view',__name__)

@views.route('/')
def home():
    return render_template("index.html")

@views.route('/accounttype')
def accounttype():
    return render_template("accounttype.html")

@views.route('/dashboard')
def dashboard():
    return render_template("dashboard.html")

@views.route('/hire')
def hire():
    return render_template("hire.html")

@views.route('/projectdetails')
def projectdetails():
    return render_template("my_project_details.html")
