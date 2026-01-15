---
layout: post
title: "Delivery Timeline"
author: "Epy Team"
permalink: /delivery-timeline/
---


<style>
/* ================================
   Content Timeline (Ledger View)
   Applies only to this page
   ================================ */

.timeline-page {
  max-width: 920px;
  margin: 0 auto;
  padding: 18px 14px;
}

.timeline-subtitle {
  margin: 0 0 14px 0;
  opacity: 0.85;
  line-height: 1.5;
}

.timeline-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.timeline-item {
  padding: 14px 12px;
  border-radius: 10px;
  background: rgba(0,0,0,0.03);
}

.timeline-title {
  font-weight: 700;
  font-size: 1.05rem;
  margin-bottom: 10px;
}

.timeline-grid {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 12px;
  align-items: start;
}

.timeline-label {
  font-size: 0.85rem;
  font-weight: 700;
  opacity: 0.75;
  margin-bottom: 6px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.timeline-brief {
  line-height: 1.55;
  opacity: 0.92;
}

.timeline-muted {
  opacity: 0.55;
}

.timeline-meta {
  padding-left: 10px;
  border-left: 1px solid rgba(0,0,0,0.10);
}

.meta-line {
  display: flex;
  gap: 8px;
  line-height: 1.55;
}

.meta-k {
  font-weight: 700;
  opacity: 0.75;
  min-width: 74px;
}

.meta-v {
  opacity: 0.95;
}

.meta-note {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px dashed rgba(0,0,0,0.15);
  opacity: 0.85;
  line-height: 1.5;
}

/* Make the CTA look like a small action */
.timeline-cta a {
  font-weight: 700;
  text-decoration: none;
  border-bottom: 1px solid currentColor;
}
.timeline-cta a:hover {
  opacity: 0.85;
}

/* Small polish */
.timeline-item a {
  text-decoration: underline;
}

/* Mobile layout */
@media (max-width: 720px) {
  .timeline-grid {
    grid-template-columns: 1fr;
  }
  .timeline-meta {
    padding-left: 0;
    border-left: none;
    border-top: 1px solid rgba(0,0,0,0.10);
    padding-top: 10px;
  }
}
</style>


This page contains our public **Content Delivery Timeline**, where you can see the topics we’re actively considering, working on, and planning to deliver — and understand what is likely to be taken up next.

The topics listed here are curated by us based on signals received from multiple channels, including YouTube comments, personal messages/DMs, insights from our corporate trainings, current trends in tech, and recurring pain points observed in practice.

For the topics shown on the timeline, you can **register your interest**. Higher interest helps us decide which topics to take up sooner, while keeping the process focused and transparent.

Every topic on this timeline is taken to a clear end state: **published, rescoped, or discontinued**. Topics are not silently dropped.

If you have a topic suggestion that isn’t listed, you’re welcome to share it via **YouTube comments (on any video)** or by reaching out through **Telegram or email**. We regularly review these inputs when curating future topics.


<div class="timeline-page">

<!-- 
  <p class="timeline-subtitle">
      This page contains our public <strong>Content Delivery Timeline</strong>, where you can see the topics we’re actively considering, working on, and planning to deliver — and understand what is likely to be taken up next.
  </p>
  <p class="timeline-subtitle">
      The topics listed here are curated by us based on signals received from multiple channels, including YouTube comments, personal messages/DMs, insights from our corporate trainings, current trends in tech, and recurring pain points observed in practice.
  </p>
  <p class="timeline-subtitle">
      For the topics shown on the timeline, you can <strong>register your interest</strong>. Higher interest helps us decide which topics to take up sooner, while keeping the process focused and transparent.
  </p>

  <p class="timeline-subtitle">
        Every topic on this timeline is taken to a clear end state: <strong>published, rescoped, or discontinued</strong>. Topics are not silently dropped.
  </p>

   <p class="timeline-subtitle">
        If you have a topic suggestion that isn’t listed, you’re welcome to share it via <strong>YouTube comments (on any video)</strong> or by reaching out through <strong>Telegram or email</strong>. We regularly review these inputs when curating future topics.
  </p>   
-->
  {% assign request_form_url = "https://forms.gle/BiKfnbV2xTdhKmcr6" %}
  {% assign topics = site.data.topics %}

  <div class="timeline-list">
    {% for t in topics %}
      {% assign title = t["Title"] | strip %}
      {% if title == "" %}
        {% continue %}
      {% endif %}

      {% assign id = t["S. No"] | strip %}
      {% assign brief = t["Description"] | strip %}
      {% assign platform = t["Platform"] | strip %}
      {% assign added = t["Added Date"] | strip %}
      {% assign requests = t["Request Count"] | plus: 0 %}
      {% assign status = t["Status"] | strip %}
      {% assign publish_date = t["Publish Date"] | strip %}
      {% assign link = t["Link"] | strip %}
      {% assign note = t["Note"] | strip %}

      <div class="timeline-item">
        <div class="timeline-title">
          {{ id }}. {{ title }}
        </div>

        <div class="timeline-grid">
          <div class="timeline-problem">
            <!--<div class="timeline-label">Problem</div> -->
            <div class="timeline-brief">
              {% if brief != "" %}
                {{ brief }}
              {% else %}
                <span class="timeline-muted">—</span>
              {% endif %}
            </div>
          </div>

          <div class="timeline-meta">
            <!-- <div class="timeline-label">Details</div> -->

            {% if status != "" %}
              <div class="meta-line"><span class="meta-k">Status:</span> <span class="meta-v">{{ status }}</span></div>
            {% endif %}

            {% if status == "Open For Requests" %}
              <div class="meta-line timeline-cta">
                <span class="meta-k">Submit:</span>
                <span class="meta-v">
                  <a href="{{ request_form_url }}" target="_blank" rel="noopener">Request this topic</a>
                </span>
              </div>
            {% endif %}


            <div class="meta-line"><span class="meta-k">Audience Requests:</span> <span class="meta-v">{{ requests }}</span></div>

            {% if platform != "" %}
              <div class="meta-line"><span class="meta-k">Platform:</span> <span class="meta-v">{{ platform }}</span></div>
            {% endif %}

            {% if added != "" %}
              <div class="meta-line"><span class="meta-k">Topic Added On:</span> <span class="meta-v">{{ added }}</span></div>
            {% endif %}

            {% if publish_date != "" %}
              <div class="meta-line"><span class="meta-k">Expected Publish Date:</span> <span class="meta-v">{{ publish_date }}</span></div>
            {% endif %}

            {% if link != "" %}
              <div class="meta-line">
                <span class="meta-k">Link:</span>
                <span class="meta-v"><a href="{{ link }}" target="_blank" rel="noopener">Open</a></span>
              </div>
            {% endif %}

            {% if note != "" %}
              <div class="meta-note">{{ note }}</div>
            {% endif %}
          </div>
        </div>
      </div>

    {% endfor %}
  </div>
</div>
