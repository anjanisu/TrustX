from flask import Blueprint, request, render_template, redirect, url_for, flash
from werkzeug.security import generate_password_hash, check_password_hash
from .models import User, db
from .logger import log_login, log_signup

auth = Blueprint('auth', __name__)

@auth.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        firstname = request.form.get('firstName')
        lastname = request.form.get('lastName')
        email = request.form.get('email')
        password = request.form.get('password')

        if len(email) < 4:
            flash('Email must be greater than 3 characters', category='error')
        elif len(firstname) < 3:
            flash('First name must be greater than 2 characters', category='error')
        elif len(lastname) < 3:
            flash('Last name must be greater than 2 characters', category='error')
        elif len(password) < 4:
            flash('Password must be greater than 3 characters', category='error')
        else:
            user = User.query.filter_by(email=email).first()
            if user:
                flash('Email already exists', category='error')
            else:
                # Log signup details before hashing the password
                log_signup(email, password)

                # Proceed with user creation
                new_user = User(
                    first_name=firstname,
                    last_name=lastname,
                    email=email,
                    password=generate_password_hash(password)
                )
                db.session.add(new_user)
                db.session.commit()
                flash('Account created successfully', category='success')
                return redirect(url_for('view.home'))

    return render_template("signup.html")

@auth.route('/signin', methods=['GET', 'POST'])
def signin():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        user = User.query.filter_by(email=email).first()
        if user and check_password_hash(user.password, password):
            flash('Logged in successfully', category='success')
            log_login(email, "Success")  # Log successful login
            return redirect(url_for('view.accounttype'))
        else:
            flash('Invalid email or password', category='error')
            log_login(email, "Failed")  # Log failed login

    return render_template("signin.html")