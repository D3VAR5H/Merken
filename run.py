import psycopg2
from flask import Flask, render_template
import os

conn = None
cur = None

user = None
user_boards = []
user_pages = []


# @app.route('/contact')
# def contact():
#     return render_template('contact.html')


def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = '9fc26a8960d2f5ed4126dde9830e49f4'

    global conn, cur
    try:
        # conn = psycopg2.connect("dbname='Merken' user='postgres' host='localhost' password='D3VAR5H'")
        conn = psycopg2.connect(
            "dbname='dc89oj5md8msl7' user='bvnjfbtlujvlhk' host='ec2-52-71-231-180.compute-1.amazonaws.com' password='dc96ec7bea1f0e8613f64ad609f516249e19e592dfab944b9e95369b4e95a6bd'")
    except:
        print("I am unable to connect to the database")
    cur = conn.cursor()

    from useraccounts import useraccounts_routes
    from boardnotes import boardnotes_routes

    app.register_blueprint(useraccounts_routes.useraccounts_bp, url_prefix='/accounts')
    app.register_blueprint(boardnotes_routes.boardnotes_bp, url_prefix='/boards')

    def get_data():
        global user
        global user_boards
        global user_pages
        if user is None:
            user = useraccounts_routes.get_user()
        user_boards = useraccounts_routes.get_boards()
        user_pages = useraccounts_routes.get_pages()

    @app.route('/')
    def index():
        return render_template('welcome.html')

    @app.route('/about')
    def about():
        get_data()
        return render_template('about.html', user=user, user_boards=user_boards, user_pages=user_pages)

    @app.route('/terms_and_conditions')
    def tc():
        return render_template('terms&condition.html')

    app.run(debug=True)

    return app
