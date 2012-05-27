---
title: "Backbone.js Collection Sub-Views"
date:  2012/05/27

---

I'm working on a feature not dissimilar to [Instapaper]'s "reading list" for a
current project, and it is predominently build in [CoffeeScript] backed up by
a Rails backend; I used [Backbone.js] for the user interface code.

Incase you are not familiar with the feature, it looks a little something like
this:

![Instapaper's reading list](http://f.cl.ly/items/0A3e1N0j1E2a2N2X3P2J/Screen%20Shot%202012-05-27%20at%2010.53.59%20AM.png)

There's a few moving pieces here, so there's the `ReadingListCollection`, a
Backbone.js collection which looks something like this:

    window.ReadingListCollection = Backbone.Collection.extend
      model: ReadingListItem

There's the `ReadingListItem` itself which has something like the following
structure:

    window.ReadingListItem = Backbone.Model.extend
      defaults:
        name: "Untitled"
        read: false
      isRead: ->
        @get 'read'
      markRead: ->
        $.ajax
          url: @get('_links').read_url
          method: 'POST'
          success: ->
            @set { read: true }

Next come the views, my application is a little unusual in that the view looks
different depending if:

  1. All the items on this reading list are unread.
  2. Some of them items on this reading list are unread.
  3. **One has started marking items on an otherwise un-read reading list as read.**
  4. There are no more unread items on this reading list.

The behaviour is something like, if the list is completely unread you see the
"working" view, easy, just as with Instapaper to click them away, delete them
or whatever you like.

If the list is partly read, then you see the "top" item in a large format, as
soon as you interact with that, the view snaps back to it's "working" mode of
operation. This *read this next* view is the application's call to action, the
client makes a little money from Amazon referrals, and uses this larger view
to encourage the users to pick up the book *now* and share a little love.

And of course, once the list is empty, there's a final state to the view, the
typical "your list is empty" state; nothing ground breaking so far.

So, in summary, before we look at how I structured the views there are three
logically distinct views:

  1. List View
  2. Focus Single Item
  3. Empty List View

So the application has four Backbone.js views:

  1. **`ReadingListControllerView`**
    1. `ReadingListView`
    2. `ReadingListFocusView`
    3. `EmptyReadingListView`

The first is a meta view, it is responsible for binding to the placeholder DOM
element in the page, being bound to the collection and receiving events. This 
view also is responsible for tracking if this reading list has yet been
interacted with since the page loaded.

One view which is also missing is the `ReadingListItemView`, this is the
smallest moving part, and exists only as a *leaf* in the UI, so we won't focus
on it much.

There's no reason this couldn't be tracked in the *Collection*, but as it's a 
view concern, I prefer to track it in the view.

Here's the simplest version of the view:

    window.ReadingListControllerView = Backbone.View.extend
      active: false      
      tagName: 'div'
      className: 'reading-list-container'
      activate: ->
        @active = true
        @render()
        this

Here we define a normal Backbone.js View, nothing special here except that
upon activation we will re-render the view.

I'm in the habit of returning `this` from functions whenever it makes sense
that they might be chained, otherwise *CoffeeScript* has a strange habit of
writing nonsense returns. (By default it returns the last statement in the
closure.)

For completenesses sake, here are the other views, in full:

    window.ReadingListView = Backbone.View.extend
      tagName: 'ul',
      className: 'reading-list'
      render: ->
        _.each @collection.first(4), (rli) ->
          @$el.append new ReadingListItemView(model: rli).render().el

    window.ReadingListFocusView = Backbone.View.extend
      tagName: 'div'
      className: 'reading-list-focus'
      events:
        "click .js-mark-as-read" : @markItemAsRead
      markItemAsRead: ->
        @model.markRead()
      render: ->
        @$el.append $("<h1>").text "You need to read " + @model.get('name') + " next"
        @$el.append $("<a class='js-mark-as-read'>").text "I've already read it."

    window.EmptyReadingListView = Backbone.View.extend
      tagName: 'div'
      className: 'empty-reading-list'
      render: ->
        @$el.append $("<p>").text("This reading list has no unread items");

    window.ReadingListItemView
      tagName: 'li'
      className: 'reading-list-item'
      events:
        "click .js-mark-as-read" : @markItemAsRead
      markItemAsRead: ->
        @model.markRead()
      render: ->
        @$el.append $("<h5>").text @model.get('name')
        @$el.append $("<a class='js-mark-as-read'>").text "I've already read it."


This buys us the structure we need to represent everything on the view-side,
there is certainly a opportunity to DRY up this code, but writing perfect
reusable code wasn't the point of this article.

We didn't write the `render` method of `ReadingListControllerView` yet, as the
logic is slightly complicated, here's a rough version:

    # The reading list only shows un-read items
    # define this method here because again this is a view concern
    # the reading list collection always contains all of the items 
    # on a  reading list
    unreadReadingListItems: ->
      collection.reject (rli) ->
        rli.isRead()

    render: ->
      @$el.empty()
      if _.empty @unreadReadingListItems
        @$el.append new EmptyReadingListView().render().el
      else
        if @activated
        
        else


## The Wiring

Now that the view layers are clear, we need to connect them to eachother,
remember that when something is marked as read we need to re-render the
`ReadingListControllerView`, and trust that this will draw the correct results
for us.

We have to track 

## Demo

There's a demo of this available at [JSFiddle] which works more or less the same
way, and is written in vanilla Javascript.

<iframe style="width: 100%; height: 300px" src="http://jsfiddle.net/pborreli/pJgyu/embedded/" allowfullscreen="allowfullscreen" frameborder="0"></iframe>

[Click here to see the demo at JSFiddle]

[JSFiddle]: http://jsfiddle.net
[Backbone.js]: http://documentcloud.github.com/backbone/
[Instapaper]: http://www.instapaper.com/
[CoffeeScript]: http://coffeescript.org/
[Click here to see the demo at JSFiddle]: http://jsfiddle.net/pborreli/pJgyu/
